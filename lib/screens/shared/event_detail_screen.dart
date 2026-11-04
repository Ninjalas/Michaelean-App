import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/campus.dart';
import '../../models/guest.dart';
import '../../models/user_profile.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/attendees_section.dart';
import '../../widgets/back_header.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/user_avatar.dart';

/// A minimal event page: just enough to register and reach the guest list
/// (spec §7.3). The full Luma-style detail (map, About, share, deadline) is
/// Phase 7 work; when it is built, keep its Register button and the
/// [AttendeesSection] and drop the rest of this file.
class EventDetailScreen extends StatefulWidget {
  final CampusService campusService;
  final String eventId;

  const EventDetailScreen({super.key, required this.campusService, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

typedef _EventData = ({CampusEvent event, GuestSummary summary});

class _EventDetailScreenState extends State<EventDetailScreen> {
  Future<_EventData?>? _data;
  String? _loadedFor; // Session.dataKey the data belongs to

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when registration changes (Session.refresh) or the account does.
    final session = SessionScope.of(context);
    if (session.user != null && session.dataKey != _loadedFor) {
      _loadedFor = session.dataKey;
      _data = _load(session.user!);
    }
  }

  Future<_EventData?> _load(UserProfile user) async {
    final event = await widget.campusService.loadEvent(user, widget.eventId);
    if (event == null) return null;
    final summary = await widget.campusService.loadGuestSummary(user, widget.eventId);
    if (summary == null) return null;
    return (event: event, summary: summary);
  }

  void _retry() => setState(() => _data = _load(SessionScope.of(context).user!));

  Future<void> _confirmCancel() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel registration?'),
        content: const Text("Your spot will be released. You can register again later "
            "if the event isn't full."),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Keep my spot')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    final session = SessionScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.campusService.cancelRegistration(session.user!, widget.eventId);
      session.refresh();
      messenger.showSnackBar(const SnackBar(
        content: Text('Registration cancelled in this preview only. Nothing was sent to the school.'),
      ));
    } on RegistrationException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text("Couldn't cancel. Please try again.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionScope.of(context).user;
    if (user == null) return const SizedBox.shrink(); // preview just ended
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const BackHeader('Event'),
            Expanded(
              child: FutureBuilder<_EventData?>(
                future: _data,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return _Message(
                      icon: Icons.error_outline_rounded,
                      title: "Couldn't load this event",
                      body: 'Check your connection and try again.',
                      action: OutlinedButton(onPressed: _retry, child: const Text('Retry')),
                    );
                  }
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snap.data;
                  if (data == null) {
                    return const _Message(
                      icon: Icons.event_busy_outlined,
                      title: 'Event not available',
                      body: "This event doesn't exist or isn't open to you.",
                    );
                  }
                  return _content(context, text, data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, TextTheme text, _EventData d) {
    final e = d.event;
    final canRegister = d.summary.state == RegistrationState.open;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 120),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: e.coverAsset != null
                ? Image.asset(e.coverAsset!, fit: BoxFit.cover)
                : const ColoredBox(
                    color: AppColors.fill,
                    child: Icon(Icons.event_outlined, size: 48, color: AppColors.muted),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(e.title, style: text.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text('${weekdayName(e.start)}, ${formatDayMonth(e.start)} · ${formatTime(e.start)}',
            style: text.bodyLarge?.copyWith(color: AppColors.muted)),
        const SizedBox(height: AppSpacing.lg),

        // Registration action.
        if (d.summary.state == RegistrationState.registered) ...[
          const Align(
              alignment: Alignment.centerLeft,
              child: StatusPill("You're registered", tone: PillTone.navy)),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
                onPressed: _confirmCancel, child: const Text('Cancel registration')),
          ),
        ] else
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  canRegister ? () => context.push('/life/events/${e.id}/register') : null,
              child: Text(switch (d.summary.state) {
                RegistrationState.full => 'Event full',
                RegistrationState.closed => 'Registration closed',
                _ => 'Register',
              }),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Text('Registration is not attendance. Only official attendance counts.',
            style: text.bodyMedium?.copyWith(color: AppColors.muted)),

        const SectionHeader('Venue'),
        Text(e.venue, style: text.bodyLarge),

        const SectionHeader('Host'),
        Row(
          children: [
            UserAvatar(name: e.host, imageAsset: e.hostLogo, size: 36),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(e.host, style: text.titleMedium)),
          ],
        ),

        AttendeesSection(
          summary: d.summary,
          onOpen: () => context.push('/life/events/${e.id}/guests'),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  const _Message({required this.icon, required this.title, required this.body, this.action});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.muted),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(body,
                style: text.bodyMedium?.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: AppSpacing.lg), action!],
          ],
        ),
      ),
    );
  }
}
