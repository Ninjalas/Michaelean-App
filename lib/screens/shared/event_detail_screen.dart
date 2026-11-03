import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../models/campus.dart';
import '../../services/campus_service.dart';
import '../../utils/dates.dart';
import '../../widgets/user_avatar.dart';

// ---------------------------------------------------------------------------
// Asset paths mapped to existing Michaelean-App assets
// ---------------------------------------------------------------------------
class EventDetailAssets {
  static const poster = 'assets/images/events/css_startupevent.jpg';
  static const map = 'assets/images/SMCL_MAP.png';
  static const georgio = 'assets/images/profiles/Sir_Georgio.png';
  static const neil = 'assets/images/profiles/Sir_Neil.png';
  static const nicolas = 'assets/images/profiles/nicolas.jpg';
  static const dion = 'assets/images/profiles/dion.jpg';
  static const jasmine = 'assets/images/profiles/jasmine.jpg';
  static const eunice = 'assets/images/profiles/eunice.png';
}

Widget _eventImage(String? asset, {required BoxFit fit}) {
  if (asset == null || asset.isEmpty) {
    return const ColoredBox(color: Color(0xFFE7E9ED));
  }
  return Image.asset(
    asset,
    fit: fit,
    errorBuilder: (context, error, stackTrace) =>
        const ColoredBox(color: Color(0xFFE7E9ED)),
  );
}

class EventDetailScreen extends StatefulWidget {
  final CampusEvent? event;
  final CampusService? campusService;

  const EventDetailScreen({super.key, this.event, this.campusService});

  @override
  State<EventDetailScreen> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailScreen> {
  CampusEvent? _updatedEvent;
  bool _isReporting = false;
  bool _isRegistering = false;
  bool _hasReported = false;

  CampusEvent? get event => _updatedEvent ?? widget.event;

  String? get _posterAsset =>
      event == null ? EventDetailAssets.poster : event!.coverAsset;

  String get _locationImage =>
      event?.locationImageAsset ?? EventDetailAssets.map;

  String get _eventTitle =>
      event?.title ??
      'Turning Ideas Into Investment: A Student\'s Guide to Start-Up Pitching';

  String get _eventDate => event == null
      ? 'Fri, 13 Feb, 1:00PM - 4:00 PM'
      : '${weekdayShort(event!.start.weekday)}, ${formatDayMonth(event!.start)} · ${formatTime(event!.start)}';

  EventRegistrationData? _registration; // null = not registered yet

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // Register button: popup -> success screen -> (optional) cancel
  Future<void> _onRegisterTap() async {
    if (_isRegistering) return;
    if (_registration == null) {
      setState(() => _isRegistering = true);
      final data = await showEventRegistrationDialog(
        context,
        eventTitle: _eventTitle,
        eventDate: _eventDate,
      );
      if (data == null || !mounted) {
        if (mounted) setState(() => _isRegistering = false);
        return;
      }
      final selectedEvent = event;
      if (selectedEvent != null) {
        final attendee = EventPerson(name: data.fullName);
        try {
          final result = widget.campusService == null
              ? (
                  event: _addLocalRegistrant(selectedEvent, attendee),
                  added: !_containsAttendee(selectedEvent, data.fullName),
                )
              : await widget.campusService!.registerForEvent(
                  selectedEvent,
                  attendee,
                );
          if (!mounted) return;
          if (!result.added) {
            _toast('You are already registered for this event.');
            setState(() => _isRegistering = false);
            return;
          }
          setState(() {
            _registration = data;
            _updatedEvent = result.event;
            _isRegistering = false;
          });
        } catch (error) {
          if (mounted) {
            setState(() => _isRegistering = false);
            _toast('Registration could not be updated: $error');
          }
          return;
        }
      } else {
        setState(() {
          _registration = data;
          _isRegistering = false;
        });
      }
    }

    if (!mounted) return;
    final cancelled = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EventRegistrationSuccessScreen(
          posterAsset: _posterAsset,
          eventTitle: event?.title,
          eventDate: event == null ? null : _eventDate,
          eventLocation: event?.venue,
        ),
      ),
    );

    if (cancelled == true && mounted) {
      final registered = _registration;
      final selectedEvent = event;
      if (registered != null && selectedEvent != null) {
        try {
          final result = widget.campusService == null
              ? (
                  event: _removeLocalRegistrant(
                    selectedEvent,
                    registered.fullName,
                  ),
                  removed: _containsAttendee(
                    selectedEvent,
                    registered.fullName,
                  ),
                )
              : await widget.campusService!.cancelEventRegistration(
                  selectedEvent,
                  registered.fullName,
                );
          if (!mounted) return;
          setState(() {
            _registration = null;
            _updatedEvent = result.event;
          });
          _toast(
            result.removed
                ? 'Registration cancelled'
                : 'This registration was already removed.',
          );
        } catch (error) {
          _toast('Registration could not be cancelled: $error');
        }
      } else {
        setState(() => _registration = null);
        _toast('Registration cancelled');
      }
    }
  }

  bool _containsAttendee(CampusEvent event, String name) {
    final normalized = name.trim().toLowerCase();
    return normalized.isNotEmpty &&
        (event.attendees ?? const <EventPerson>[]).any(
          (person) => person.name.trim().toLowerCase() == normalized,
        );
  }

  CampusEvent _addLocalRegistrant(CampusEvent event, EventPerson attendee) {
    if (_containsAttendee(event, attendee.name)) return event;
    final attendees = event.attendees ?? const <EventPerson>[];
    final count = (event.attendeeCount ?? attendees.length)
        .clamp(attendees.length, 0x7fffffff)
        .toInt();
    return event.copyWith(
      attendees: [...attendees, attendee],
      attendeeCount: count + 1,
    );
  }

  CampusEvent _removeLocalRegistrant(CampusEvent event, String name) {
    final normalized = name.trim().toLowerCase();
    final attendees = event.attendees ?? const <EventPerson>[];
    final remaining = attendees
        .where((person) => person.name.trim().toLowerCase() != normalized)
        .toList();
    if (remaining.length == attendees.length) return event;
    final count = (event.attendeeCount ?? attendees.length)
        .clamp(attendees.length, 0x7fffffff)
        .toInt();
    return event.copyWith(
      attendees: remaining,
      attendeeCount: count > 0 ? count - 1 : 0,
    );
  }

  Future<String?> _confirmReport() {
    final reasonController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Report event?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This demo records the report locally in memory only. '
              'It is not sent to a server.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(reasonController.text.trim()),
            child: const Text('Report'),
          ),
        ],
      ),
    ).whenComplete(reasonController.dispose);
  }

  Future<void> _reportEvent() async {
    if (_isReporting || _hasReported) return;
    final reason = await _confirmReport();
    if (reason == null || !mounted) return;
    setState(() => _isReporting = true);
    try {
      final selectedEvent = event;
      if (selectedEvent == null || widget.campusService == null) {
        setState(() => _hasReported = true);
        _toast('Demo report noted in this view only; not saved or sent.');
        return;
      }
      final recorded = await widget.campusService!.reportEvent(
        selectedEvent,
        reason: reason,
      );
      if (!mounted) return;
      setState(() => _hasReported = true);
      _toast(
        recorded
            ? 'Report recorded locally for this demo session; not sent to a server.'
            : 'This event was already reported in this demo session.',
      );
    } catch (error) {
      if (mounted) _toast('Report could not be recorded: $error');
    } finally {
      if (mounted) setState(() => _isReporting = false);
    }
  }

  // Contact host: opens a message form.
  // This is a UI prototype; it does not send messages to a real host/backend.
  Future<void> _showContactHost() async {
    final messageController = TextEditingController();

    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Contact Host',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Send a message to the event organizers.',
                style: TextStyle(height: 1.4, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type your message here...',
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (messageController.text.trim().isEmpty) return;
              Navigator.of(dialogContext).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    final hasMessage = messageController.text.trim().isNotEmpty;
    messageController.dispose();

    if (!mounted) return;
    if (shouldSend == true && hasMessage) {
      _toast('Message prepared. Sending is not connected yet.');
    }
  }

  // More menu: copy event details or open a simple report confirmation.
  void _showMoreOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'More options',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('Copy event details'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await Clipboard.setData(
                    ClipboardData(
                      text:
                          '$_eventTitle\nDate: $_eventDate\nLocation: ${event?.venue ?? 'Saint Beatrice Ballroom'}',
                    ),
                  );
                  if (mounted) _toast('Event details copied to clipboard');
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Share event details'),
                subtitle: const Text(
                  'Copies the event details so you can share them',
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await Clipboard.setData(
                    ClipboardData(
                      text:
                          '$_eventTitle\nDate: $_eventDate\nLocation: ${event?.venue ?? 'Saint Beatrice Ballroom'}',
                    ),
                  );
                  if (mounted) {
                    _toast(
                      'Event details copied. You can paste and share them.',
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Report event'),
                enabled: !_hasReported && !_isReporting,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _reportEvent();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMap(String imageAsset) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Image.asset(
              imageAsset,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const ColoredBox(color: Color(0xFF202020)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackButton(onTap: () => Navigator.maybePop(context)),
                  const SizedBox(height: 12),

                  // Poster
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _eventImage(_posterAsset, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title + date
                  Text(
                    _eventTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_eventDate, style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),

                  // Action pill
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: _pillDecoration(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ActionButton(
                            icon: _registration == null
                                ? Icons.confirmation_number_outlined
                                : Icons.check_circle_outline,
                            label: _registration == null
                                ? 'Register'
                                : 'Registered',
                            onTap: _onRegisterTap,
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            icon: Icons.mail_outline,
                            label: 'Contact',
                            onTap: _showContactHost,
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            icon: Icons.more_horiz,
                            label: 'More',
                            onTap: _showMoreOptions,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Location
                  const _SectionTitle('Location'),
                  const SizedBox(height: 16),
                  Text(
                    event?.venue ?? 'Saint Beatrice Ballroom',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _openMap(_locationImage),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 170,
                        width: double.infinity,
                        child: _eventImage(_locationImage, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Hosts / Speaker
                  const _SectionTitle('Hosts/Speaker'),
                  const SizedBox(height: 14),
                  if (event == null) ...[
                    _PersonRow(
                      image: 'assets/images/profiles/css_profile.jpg',
                      name: 'Computer Science Society',
                      onTap: () => context.push('/life/community/css'),
                    ),
                    const SizedBox(height: 12),
                    _PersonRow(
                      image: EventDetailAssets.georgio,
                      name: 'Mr. Giorgio Armani Magno',
                      onTap: () =>
                          context.push('/life/community/speaker-georgio'),
                    ),
                    const SizedBox(height: 12),
                    _PersonRow(
                      image: EventDetailAssets.neil,
                      name: 'Neil Preach Aczon',
                      onTap: () => context.push('/life/community/speaker-neil'),
                    ),
                  ] else ...[
                    _PersonRow(
                      image: event!.hostLogo,
                      name: event!.host,
                      onTap: event!.hostProfileId == null
                          ? null
                          : () => context.push(
                              '/life/community/${event!.hostProfileId}',
                            ),
                    ),
                    for (final speaker
                        in event!.speakers ?? const <EventPerson>[]) ...[
                      const SizedBox(height: 12),
                      _PersonRow(
                        image: speaker.imageAsset,
                        name: speaker.name,
                        onTap: speaker.profileId == null
                            ? null
                            : () => context.push(
                                '/life/community/${speaker.profileId}',
                              ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 20),

                  // Attendees
                  if (event == null) ...[
                    const Text(
                      '70 going',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _AttendeeStack(
                      people: [
                        EventPerson(
                          name: 'Nicolas Santos',
                          imageAsset: EventDetailAssets.nicolas,
                        ),
                        EventPerson(
                          name: 'Dion Casalla',
                          imageAsset: EventDetailAssets.dion,
                        ),
                        EventPerson(
                          name: 'Jasmine Pascual',
                          imageAsset: EventDetailAssets.jasmine,
                        ),
                        EventPerson(
                          name: 'Eunice Palad',
                          imageAsset: EventDetailAssets.eunice,
                        ),
                      ],
                      extra: 66,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Nicolas Santos, Dion Casalla, Jasmine Pascual, Eunice Palad, and 66 more',
                      style: TextStyle(fontSize: 16, height: 1.35),
                    ),
                  ] else
                    _EventAttendeePreview(event: event!),
                  const SizedBox(height: 28),

                  // About
                  const _SectionTitle('About Event'),
                  const SizedBox(height: 16),
                  if (event == null) ...[
                    const Text(
                      'Ready to elevate your startup idea into an investment-worthy pitch?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text.rich(
                      TextSpan(
                        style: TextStyle(fontSize: 15, height: 1.45),
                        children: [
                          TextSpan(text: 'Join us for '),
                          TextSpan(
                            text: 'Turning Ideas Into Investment: A Student\'s Guide to Start-Up Pitching',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: ', a seminar-workshop designed to help students communicate their ideas with clarity, confidence, and real-world impact.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Learn how to:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _Bullet('Define a compelling problem'),
                    const _Bullet('Highlight a strong value proposition'),
                    const _Bullet('Understand and analyze your target market'),
                    const _Bullet(
                      'Tailor your message for investors and corporate stakeholders',
                    ),
                    const _Bullet(
                      'Present with confidence in both academic and entrepreneurial settings',
                    ),
                  ] else
                    Text(
                      event!.description?.trim().isNotEmpty == true
                          ? event!.description!.trim()
                          : 'No event description is available yet.',
                      style: const TextStyle(fontSize: 15, height: 1.45),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared styling
// ---------------------------------------------------------------------------
BoxDecoration _pillDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(40),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withAlpha(36),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ],
);

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Back',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, size: 18),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 6),
        Divider(height: 1, color: Colors.grey.shade300),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  final String? image;
  final String name;
  final VoidCallback? onTap;

  const _PersonRow({
    required this.image,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: onTap == null ? name : 'Open $name profile',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade300,
                child: UserAvatar(name: name, imageAsset: image, size: 36),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendeeStack extends StatelessWidget {
  final List<EventPerson> people;
  final int extra;
  const _AttendeeStack({required this.people, required this.extra});

  @override
  Widget build(BuildContext context) {
    const double radius = 25;
    const double step = 34;
    final double width = people.isEmpty
        ? 0
        : step * (people.length - 1) + radius * 2 + (extra > 0 ? step : 0);

    return SizedBox(
      height: radius * 2,
      width: width,
      child: Stack(
        children: [
          for (int i = 0; i < people.length; i++)
            Positioned(
              left: i * step,
              child: CircleAvatar(
                radius: radius,
                backgroundColor: Colors.white,
                child: UserAvatar(
                  name: people[i].name,
                  imageAsset: people[i].imageAsset,
                  size: (radius - 2) * 2,
                ),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: people.length * step,
              child: CircleAvatar(
                radius: radius,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: radius - 2,
                  backgroundColor: Colors.grey.shade300,
                  child: Text(
                    '+$extra',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventAttendeePreview extends StatelessWidget {
  final CampusEvent event;

  const _EventAttendeePreview({required this.event});

  @override
  Widget build(BuildContext context) {
    final people = <EventPerson>[];
    final names = <String>{};
    for (final person in event.attendees ?? const <EventPerson>[]) {
      final name = person.name.trim();
      if (name.isNotEmpty && names.add(name)) people.add(person);
    }

    final reportedCount = (event.attendeeCount ?? people.length)
        .clamp(0, 0x7fffffff)
        .toInt();
    final count = reportedCount > people.length ? reportedCount : people.length;
    final visiblePeople = people.take(4).toList();
    final remaining = count > visiblePeople.length
        ? count - visiblePeople.length
        : 0;
    final visibleNames = visiblePeople.map((person) => person.name).toList();
    final namesLabel = visibleNames.isEmpty
        ? 'Attendee names are not available yet.'
        : '${visibleNames.join(', ')}${remaining > 0 ? ', and $remaining more' : ''}';

    if (count == 0) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendees',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          Text('Attendee information is not available yet.'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count going',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        if (visiblePeople.isNotEmpty) ...[
          const SizedBox(height: 12),
          _AttendeeStack(people: visiblePeople, extra: remaining),
        ],
        const SizedBox(height: 12),
        Text(namesLabel, style: const TextStyle(fontSize: 16, height: 1.35)),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(fontSize: 15, height: 1.45)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// REGISTRATION POPUP
// ===========================================================================
/// The info the student typed into the registration form.
class EventRegistrationData {
  final String fullName;
  final String course;
  final String yearLevel;

  const EventRegistrationData({
    required this.fullName,
    required this.course,
    required this.yearLevel,
  });
}

/// Shows the registration popup.
/// Returns the filled-in data when the student taps Register,
/// or null when they close the popup.
Future<EventRegistrationData?> showEventRegistrationDialog(
  BuildContext context, {
  String? eventTitle,
  String? eventDate,
}) {
  return showDialog<EventRegistrationData>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) =>
        EventRegistrationDialog(eventTitle: eventTitle, eventDate: eventDate),
  );
}

class EventRegistrationDialog extends StatefulWidget {
  final String? eventTitle;
  final String? eventDate;

  const EventRegistrationDialog({super.key, this.eventTitle, this.eventDate});

  @override
  State<EventRegistrationDialog> createState() =>
      _EventRegistrationDialogState();
}

class _EventRegistrationDialogState extends State<EventRegistrationDialog> {
  final _nameCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();

  bool get _isComplete =>
      _nameCtrl.text.trim().isNotEmpty &&
      _courseCtrl.text.trim().isNotEmpty &&
      _yearCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Rebuild whenever the user types so the Register button can change color.
    for (final c in [_nameCtrl, _courseCtrl, _yearCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _courseCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      EventRegistrationData(
        fullName: _nameCtrl.text.trim(),
        course: _courseCtrl.text.trim(),
        yearLevel: _yearCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: label + close button
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'EVENT REGISTRATION',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.6,
                      color: Colors.black54,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Event title + date
            Text(
              widget.eventTitle ?? 'Turning Ideas Into Investment: A Student\'s Guide to Start-Up Pitching',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.eventDate ?? 'Fri, 13 Feb · 1:00 PM - 4:00 PM',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade300),
            const SizedBox(height: 16),

            // Fields
            const _FieldLabel('Full Name'),
            _InputField(
              controller: _nameCtrl,
              hint: 'Enter your full name',
              textInputAction: TextInputAction.next,
              capitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            const _FieldLabel('Course'),
            _InputField(
              controller: _courseCtrl,
              hint: 'e.g., BS Computer Science',
              textInputAction: TextInputAction.next,
              capitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            const _FieldLabel('Year Level'),
            _InputField(
              controller: _yearCtrl,
              hint: 'e.g., 3rd Year',
              textInputAction: TextInputAction.done,
              capitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 22),

            // Register button: gray until every field is filled
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isComplete ? _submit : null,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF111111),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF9CA3AF),
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Register',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputAction textInputAction;
  final TextCapitalization capitalization;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.textInputAction,
    required this.capitalization,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: textInputAction,
      textCapitalization: capitalization,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        filled: true,
        fillColor: const Color(0xFFF4F5F7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black87, width: 1),
        ),
      ),
    );
  }
}

// ===========================================================================
// REGISTRATION SUCCESS + CANCEL REGISTRATION
// ===========================================================================
/// Shown after a successful registration.
///
/// Pops with `true` when the student cancels their registration,
/// and with `null` when they just close the screen.
class EventRegistrationSuccessScreen extends StatelessWidget {
  /// Path of the event poster, e.g. EventDetailAssets.poster from main.dart
  final String? posterAsset;
  final String? eventTitle;
  final String? eventDate;
  final String? eventLocation;

  const EventRegistrationSuccessScreen({
    super.key,
    required this.posterAsset,
    this.eventTitle,
    this.eventDate,
    this.eventLocation,
  });

  static const _green = Color(0xFF22A06B);
  static const _red = Color(0xFFE11D2E);

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancel registration?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Your spot for this event will be released. '
          'You can register again later if slots are still available.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Keep my spot',
              style: TextStyle(color: Colors.black87),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Yes, cancel',
              style: TextStyle(color: _red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              // Header: SUCCESS label + close button
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'SUCCESS',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.6,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16),
                    ),
                  ),
                ],
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 28),
                      Container(
                        width: 68,
                        height: 68,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE6F7EE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 32, color: _green),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'You\'re Registered!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your spot for this event has been confirmed. See you there!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _EventSummaryCard(
                        posterAsset: posterAsset,
                        title: eventTitle,
                        date: eventDate,
                        location: eventLocation,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Cancel Registration button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => _confirmCancel(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _red,
                    side: const BorderSide(color: _red, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Cancel Registration',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventSummaryCard extends StatelessWidget {
  final String? posterAsset;
  final String? title;
  final String? date;
  final String? location;

  const _EventSummaryCard({
    required this.posterAsset,
    this.title,
    this.date,
    this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 8,
              child: _eventImage(posterAsset, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title ?? 'Turning Ideas Into Investment: A Student\'s Guide to Start-Up Pitching',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            text: date ?? 'Fri, 13 Feb · 1:00 PM - 4:00 PM',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.location_on_outlined,
            text: location ?? 'Saint Beatrice Ballroom (Campus Center)',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
