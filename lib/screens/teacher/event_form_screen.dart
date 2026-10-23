import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/campus.dart';
import '../../models/user_profile.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/back_header.dart';

/// Create or edit an event (spec §9.2): one scrolling page in Luma's form
/// style, with Save draft and Publish at the bottom. Editing a published
/// event saves the same event. Nothing is really published, and no one is
/// notified; the confirmation says so. With [hostOrgId], a new event hosted
/// by a club the user advises.
class EventFormScreen extends StatefulWidget {
  final CampusService campusService;
  final String? eventId; // null → a new event
  final String? hostOrgId;

  const EventFormScreen({
    super.key,
    required this.campusService,
    this.eventId,
    this.hostOrgId,
  });

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  Future<EventDetail?>? _load;
  final _title = TextEditingController();
  final _venue = TextEditingController();
  final _capacity = TextEditingController();
  final _description = TextEditingController();
  late DateTime _day;
  var _start = const TimeOfDay(hour: 13, minute: 0);
  var _end = const TimeOfDay(hour: 15, minute: 0);
  DateTime? _deadline; // a day; registration closes at its end
  String? _audience; // null → school-wide
  String? _cover;
  EventStatus? _status; // null → new
  int _registered = 0;
  Organization? _club; // the hosting club, once checked
  bool _clubChecked = false;
  bool _clubFailed = false; // couldn't check, which isn't the same as "not adviser"
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _day = DateTime(now.year, now.month, now.day + 7);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.hostOrgId != null && !_clubChecked && _club == null) {
      widget.campusService.loadAdvisedClubs(SessionScope.of(context).user!).then((clubs) {
        if (!mounted) return;
        setState(() {
          _club = clubs.where((c) => c.org.id == widget.hostOrgId).firstOrNull?.org;
          _audience ??= _club?.name; // members only, unless changed
          _clubChecked = true;
        });
      }, onError: (_) {
        if (mounted) {
          setState(() {
            _clubChecked = true;
            _clubFailed = true;
          });
        }
      });
    }
    if (widget.eventId == null || _load != null) return;
    _load = widget.campusService
        .loadEvent(SessionScope.of(context).user!, widget.eventId!)
        .then((d) {
      if (d != null && d.canManage && mounted) {
        final e = d.event;
        setState(() {
          _title.text = e.title;
          _venue.text = e.venue;
          _capacity.text = e.capacity?.toString() ?? '';
          _description.text = e.description;
          _day = DateTime(e.start.year, e.start.month, e.start.day);
          _start = TimeOfDay.fromDateTime(e.start);
          _end = TimeOfDay.fromDateTime(e.end);
          _deadline = e.deadline;
          _audience = e.audience;
          _cover = e.coverAsset;
          _status = e.status;
          _registered = d.going;
        });
      }
      return d;
    });
  }

  @override
  void dispose() {
    for (final c in [_title, _venue, _capacity, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  DateTime _on(TimeOfDay t) => _day.add(Duration(hours: t.hour, minutes: t.minute));

  DateTime? get _deadlineAt => _deadline == null
      ? null
      : DateTime(_deadline!.year, _deadline!.month, _deadline!.day, 23, 59);

  int? get _capacityValue => int.tryParse(_capacity.text.trim());

  bool get _isPublished => _status == EventStatus.published;

  /// The form's first problem when saved as [publishing], or null.
  String? _problem({required bool publishing}) {
    if (_capacity.text.trim().isNotEmpty && _capacityValue == null) {
      return 'Capacity must be a whole number.';
    }
    var deadline = _deadlineAt;
    // A deadline on the event day itself means "until it starts".
    if (deadline != null && deadline.isAfter(_on(_start))) deadline = _on(_start);
    return eventFormProblem(
      title: _title.text,
      venue: _venue.text,
      start: _on(_start),
      end: _on(_end),
      deadline: deadline,
      capacity: _capacityValue,
      registered: _registered,
      publishing: publishing,
      now: DateTime.now(),
    );
  }

  Future<void> _save({required bool publish}) async {
    final session = SessionScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final wasPublished = _isPublished;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final deadline = _deadlineAt;
      await widget.campusService.saveEvent(
        session.user!,
        eventId: widget.eventId,
        publish: publish,
        title: _title.text,
        start: _on(_start),
        end: _on(_end),
        venue: _venue.text,
        audience: _audience,
        deadline: deadline != null && deadline.isAfter(_on(_start)) ? _on(_start) : deadline,
        capacity: _capacityValue,
        description: _description.text,
        coverAsset: _cover,
        hostOrgId: widget.hostOrgId,
      );
    } catch (e) {
      // Never claim success when the save failed.
      final reason = e is ArgumentError ? '${e.message}' : e is StateError ? e.message : null;
      if (mounted) setState(() => _error = 'Not saved. ${reason ?? "Couldn't reach the service."}');
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    router.pop();
    session.refresh(); // after closing (see AttendanceReviewScreen._finalize)
    messenger.showSnackBar(SnackBar(
      content: Text(wasPublished
          ? 'Changes saved in this preview only. Registered students were not notified.'
          : publish
              ? 'Published in this preview only. Students were not notified.'
              : 'Draft saved in this preview only.'),
    ));
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _day.isBefore(now) ? now : _day,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (picked != null) setState(() => _day = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(context: context, initialTime: isStart ? _start : _end);
    if (picked != null) setState(() => isStart ? _start = picked : _end = picked);
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? (_day.isAfter(today) ? _day : today),
      firstDate: today,
      lastDate: _day.isBefore(today) ? today : _day,
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _pickCover() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true, // as tall as the photo grid needs
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Cover photo', style: Theme.of(sheet).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                children: [
                  _coverOption(sheet, null),
                  for (final c in widget.campusService.eventCovers) _coverOption(sheet, c),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _cover = picked.isEmpty ? null : picked);
  }

  Widget _coverOption(BuildContext sheet, String? asset) => Semantics(
        button: true,
        selected: asset == _cover,
        label: asset == null ? 'No photo' : 'Cover photo option',
        child: InkWell(
          onTap: () => Navigator.pop(sheet, asset ?? ''),
          borderRadius: BorderRadius.circular(AppRadius.small),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.small),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.fill,
                border: asset == _cover ? Border.all(color: AppColors.navy, width: 3) : null,
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: asset == null
                  ? const Icon(Icons.hide_image_outlined, color: AppColors.muted)
                  : Image.asset(asset, fit: BoxFit.cover),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final user = SessionScope.of(context).user!;
    final isNew = widget.eventId == null;
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<EventDetail?>(
          future: _load,
          builder: (context, snap) {
            final loading = !isNew && snap.connectionState != ConnectionState.done;
            final denied = !isNew && !loading && !(snap.data?.canManage ?? false);
            final cancelled = _status == EventStatus.cancelled;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BackHeader(isNew
                    ? widget.hostOrgId != null
                        ? 'New Club Event'
                        : 'Create Event'
                    : 'Edit Event'),
                if (widget.hostOrgId != null && !_clubChecked)
                  const LinearProgressIndicator()
                else if (widget.hostOrgId != null && _club == null)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    child: Text(
                        _clubFailed
                            ? "Couldn't load this club."
                            : "You aren't an adviser of this club.",
                        style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                  )
                else if (loading)
                  const LinearProgressIndicator()
                else if (snap.hasError)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    child: Text("Couldn't load this event.",
                        style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                  )
                else if (denied || !user.can(Permission.manageEvents) || cancelled)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    child: Text(
                        cancelled ? 'This event was cancelled.' : "You can't edit this event.",
                        style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                  )
                else ...[
                  Expanded(child: _form(user)),
                  _buttons(),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _form(UserProfile user) {
    final text = Theme.of(context).textTheme;
    // Mock assumption: a teacher may target the whole school or their own
    // department. Organization audiences are kept when editing.
    final audiences = <String?>[
      null,
      ...user.tags.where((t) => t.kind == TagKind.department).map((t) => t.label),
      if (_club != null) _club!.name,
      if (_audience != null &&
          _audience != _club?.name &&
          !user.tags.any((t) => t.label == _audience))
        _audience,
    ];
    final problem = _problem(publishing: true);
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 0),
      children: [
        Center(
          child: SizedBox(
            width: 200,
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    child: _cover != null
                        ? Image.asset(_cover!, fit: BoxFit.cover)
                        : const ColoredBox(
                            color: AppColors.navyTint,
                            child: Icon(Icons.event_outlined, size: 56, color: AppColors.navy),
                          ),
                  ),
                  Positioned(
                    right: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                    child: IconButton.filled(
                      tooltip: 'Choose cover photo',
                      onPressed: _pickCover,
                      style: IconButton.styleFrom(
                          backgroundColor: AppColors.white, foregroundColor: AppColors.ink),
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _title,
          onChanged: (_) => setState(() {}),
          style: text.titleLarge,
          decoration: const InputDecoration(hintText: 'Event name'),
        ),
        _label('Date and time'),
        _PickerTile(
          value: '${weekdayName(_day)}, ${formatDayMonth(_day)}',
          icon: Icons.calendar_today_outlined,
          semanticLabel: 'Event date',
          onTap: _pickDay,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _PickerTile(
                prefix: 'Starts',
                value: formatTime(_on(_start)),
                onTap: () => _pickTime(true),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _PickerTile(
                prefix: 'Ends',
                value: formatTime(_on(_end)),
                onTap: () => _pickTime(false),
              ),
            ),
          ],
        ),
        _label('Venue'),
        TextField(
          controller: _venue,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'e.g. Milagros Limaco Hall'),
        ),
        _label('Audience'),
        DropdownButtonFormField<String?>(
          initialValue: _audience,
          isExpanded: true, // long department names shorten instead of overflowing
          items: [
            for (final a in audiences)
              DropdownMenuItem(
                value: a,
                child: Text(
                    a == null
                        ? 'School-wide'
                        : a == _club?.name
                            ? 'Members of $a'
                            : a,
                    overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (a) => setState(() => _audience = a),
        ),
        _label('Registration'),
        _PickerTile(
          value: _deadline == null
              ? 'Open until the event starts'
              : 'Register by ${formatDayMonth(_deadline!)}',
          icon: Icons.event_available_outlined,
          semanticLabel: 'Registration deadline',
          onTap: _pickDeadline,
          onClear: _deadline == null ? null : () => setState(() => _deadline = null),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _capacity,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Capacity (optional, no limit)'),
        ),
        _label('Description'),
        TextField(
          controller: _description,
          minLines: 3,
          maxLines: 8,
          maxLength: 600,
          decoration: const InputDecoration(hintText: 'What should students know?'),
        ),
        if (_error != null || problem != null)
          Text(_error ?? problem!, style: text.bodyMedium?.copyWith(color: AppColors.red)),
        if (_isPublished) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Time and venue changes are marked on the event. In this preview, '
            'no one is notified.',
            style: text.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buttons() {
    final canPublish = !_saving && _problem(publishing: true) == null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.lg),
      child: _isPublished
          ? FilledButton(
              onPressed: canPublish ? () => _save(publish: true) : null,
              child: Text(_saving ? 'Saving…' : 'Save Changes'),
            )
          : Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52)),
                    onPressed: !_saving && _problem(publishing: false) == null
                        ? () => _save(publish: false)
                        : null,
                    child: const Text('Save draft'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: canPublish ? () => _save(publish: true) : null,
                    child: Text(_saving ? 'Saving…' : 'Publish'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
        child: Text(s,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.muted)),
      );
}

/// A soft gray rounded field that opens a picker (spec §2.1 Forms).
class _PickerTile extends StatelessWidget {
  final String value;
  final IconData? icon;
  final String? prefix; // small muted label before the value, e.g. "Starts"
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String? semanticLabel;

  const _PickerTile({
    required this.value,
    this.icon,
    this.prefix,
    required this.onTap,
    this.onClear,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fill,
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Padding(
          padding: EdgeInsets.only(
              left: AppSpacing.lg, right: onClear == null ? AppSpacing.lg : 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: AppColors.muted),
                  const SizedBox(width: AppSpacing.sm),
                ],
                if (prefix != null) ...[
                  Flexible(
                    child: Text(prefix!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.muted)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Semantics(
                    label: semanticLabel,
                    child: Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge),
                  ),
                ),
                if (onClear != null)
                  IconButton(
                    tooltip: 'Remove deadline',
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
