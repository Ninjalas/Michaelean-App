import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/campus.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/back_header.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/user_avatar.dart';

/// One event, Luma style (spec §7.3): cover, title, time, a row of actions,
/// then Venue, Host, Attendees, Registration, and About. Students register
/// here; the event's managers get Edit, Invite, and More instead (spec §9.2).
/// Everything changes this preview only.
class EventDetailScreen extends StatefulWidget {
  final CampusService campusService;
  final String eventId;

  const EventDetailScreen({super.key, required this.campusService, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Future<EventDetail?>? _data;
  String? _loadedFor;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (session.user != null && session.dataKey != _loadedFor) {
      _loadedFor = session.dataKey;
      _data = widget.campusService.loadEvent(session.user!, widget.eventId);
    }
  }

  /// Runs a preview action; says plainly what happened, and never claims
  /// success when it failed.
  Future<void> _run(Future<void> Function() action,
      {required String done, required String failed}) async {
    final session = SessionScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
    } on StateError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$failed ${e.message}')));
      return;
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text("$failed Couldn't reach the service.")));
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    session.refresh(); // reloads this page and the lists behind it
    messenger.showSnackBar(SnackBar(content: Text(done)));
  }

  void _register() {
    final user = SessionScope.of(context).user!;
    _run(
      () => widget.campusService.register(user, widget.eventId),
      done: "Registered in this preview only. This isn't an official registration.",
      failed: 'Not registered.',
    );
  }

  void _share() => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sharing isn't available in this preview.")));

  Future<void> _cancelEvent() async {
    final user = SessionScope.of(context).user!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this event?'),
        content: const Text(
            'Registered students would be notified. In this preview, no one is notified.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false), child: const Text('Keep event')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Cancel event'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    _run(
      () => widget.campusService.cancelEvent(user, widget.eventId),
      done: 'Event cancelled in this preview only. No one was notified.',
      failed: 'Not cancelled.',
    );
  }

  void _more(EventDetail d) {
    final now = DateTime.now();
    final e = d.event;
    final upcoming = e.start.isAfter(now);
    final user = SessionScope.of(context).user!;
    final items = <(IconData, String, VoidCallback, bool)>[
      if (d.canManage) ...[
        (Icons.people_outline_rounded, 'View registrations',
            () => context.push('/life/events/${e.id}/registrations'), false),
        if (e.status != EventStatus.cancelled && upcoming)
          (Icons.event_busy_outlined, 'Cancel event', _cancelEvent, true),
      ] else if (d.registered && upcoming && e.status == EventStatus.published)
        (
          Icons.close_rounded,
          'Cancel registration',
          () => _run(
                () => widget.campusService.cancelRegistration(user, e.id),
                done: 'Registration cancelled in this preview only.',
                failed: 'Still registered.',
              ),
          true,
        ),
    ];
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (items.isEmpty)
                const ListTile(title: Text('No other actions for this event.')),
              for (final (icon, label, onTap, danger) in items)
                ListTile(
                  leading: Icon(icon, color: danger ? AppColors.red : AppColors.ink),
                  title: Text(label,
                      style: TextStyle(color: danger ? AppColors.red : AppColors.ink)),
                  onTap: () {
                    Navigator.pop(sheet);
                    onTap();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<EventDetail?>(
          future: _data,
          builder: (context, snap) {
            final d = snap.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BackHeader('Event'),
                Expanded(
                  child: snap.hasError
                      ? const Center(child: Text("Couldn't load this event."))
                      // While reloading after an action, keep showing the
                      // last version instead of a blank page.
                      : snap.connectionState != ConnectionState.done && !snap.hasData
                          ? const Align(
                              alignment: Alignment.topCenter, child: LinearProgressIndicator())
                          : d == null
                              ? Padding(
                                  padding: const EdgeInsets.all(AppSpacing.screen),
                                  child: Text("This event isn't available to you.",
                                      style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                                )
                              : _content(d),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _content(EventDetail d) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyLarge?.copyWith(color: AppColors.muted);
    final e = d.event;
    final now = DateTime.now();
    final upcoming = e.start.isAfter(now);
    final live = e.status == EventStatus.published && upcoming;
    final statusPill = switch (e.status) {
      EventStatus.draft => const StatusPill('Draft'),
      EventStatus.cancelled => const StatusPill('Cancelled', tone: PillTone.red),
      _ => e.end.isAfter(now) ? null : const StatusPill('Ended'),
    };

    final actions = d.canManage
        ? [
            _Action(Icons.edit_outlined, 'Edit',
                e.status == EventStatus.cancelled || !upcoming
                    ? null
                    : () => context.push('/life/events/${e.id}/edit')),
            _Action(Icons.person_add_alt_rounded, 'Invite',
                live ? () => context.push('/life/events/${e.id}/invite') : null),
            _Action(Icons.more_horiz_rounded, 'More', () => _more(d)),
          ]
        : [
            d.registered
                ? const _Action(Icons.check_circle_outline_rounded, 'Registered', null)
                : _Action(Icons.how_to_reg_outlined, _busy ? 'Registering…' : 'Register',
                    d.closedReason != null || _busy ? null : _register),
            _Action(Icons.ios_share_rounded, 'Share', _share),
            _Action(Icons.more_horiz_rounded, 'More', () => _more(d)),
          ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 120),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: AspectRatio(
            aspectRatio: 1,
            child: e.coverAsset != null
                ? Image.asset(e.coverAsset!, fit: BoxFit.cover)
                : const ColoredBox(
                    color: AppColors.navyTint,
                    child: Icon(Icons.event_outlined, size: 64, color: AppColors.navy),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (statusPill != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Align(alignment: Alignment.centerLeft, child: statusPill),
          ),
        Text(e.title, style: text.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${weekdayName(e.start)}, ${formatDayMonth(e.start)} · '
          '${formatTime(e.start)} – ${formatTime(e.end)}',
          style: muted,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (d.registered && e.status == EventStatus.published)
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.green),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  d.invited ? 'Registered by a teacher’s invitation' : "You're registered",
                  style: text.bodyLarge?.copyWith(color: AppColors.green),
                ),
              ),
            ],
          )
        else if (d.closedReason != null && !d.canManage)
          Text(d.closedReason!, style: muted),
        if (e.updateNote != null && e.status == EventStatus.published) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.amberTint,
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Row(
              children: [
                const Icon(Icons.update_rounded, size: 18, color: AppColors.amber),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Updated: ${e.updateNote}',
                      style: text.bodyMedium?.copyWith(color: AppColors.amber)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(child: actions[i]),
            ],
          ],
        ),

        _label('Venue'),
        Text(e.venue, style: text.titleMedium),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset('assets/images/SMCL_MAP.png',
                fit: BoxFit.cover, semanticLabel: 'Campus map'),
          ),
        ),

        _label('Host'),
        Row(
          children: [
            UserAvatar(name: e.host, imageAsset: e.hostLogo, size: 40),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(e.host, style: text.titleMedium)),
          ],
        ),

        _label('Attendees'),
        Row(
          children: [
            const _AvatarStack(),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text('${d.going} registered', style: text.titleMedium)),
            if (d.canManage)
              Flexible(
                child: TextButton(
                  onPressed: () => context.push('/life/events/${e.id}/registrations'),
                  child: const Text('View all ›', maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        // Mock assumption for open decision 4: names are for managers only.
        Text("Names are shown to the event's managers only.",
            style: text.bodyMedium?.copyWith(color: AppColors.muted)),

        if (e.deadline != null || e.capacity != null) ...[
          _label('Registration'),
          if (e.deadline != null)
            Text('Register by ${weekdayName(e.deadline!)}, ${formatDayMonth(e.deadline!)}, '
                '${formatTime(e.deadline!)}',
                style: text.bodyLarge),
          if (e.capacity != null)
            Text(
              d.going >= e.capacity!
                  ? '${e.capacity} spots · Full'
                  : '${e.capacity} spots · ${e.capacity! - d.going} left',
              style: text.bodyLarge,
            ),
        ],

        _label('About'),
        Text(e.description.isEmpty ? 'No description yet.' : e.description,
            style: e.description.isEmpty ? muted : text.bodyLarge),

        const SizedBox(height: AppSpacing.section),
        Text(
          "Preview only. Registering here isn't an official registration, and it "
          "isn't attendance.",
          style: text.bodyMedium?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.section, bottom: AppSpacing.sm),
        child: Semantics(
          header: true,
          child: Text(s,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.muted)),
        ),
      );
}

/// One of the three square-ish action tiles under the title (Luma).
class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap; // null → disabled

  const _Action(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    final color = onTap == null ? AppColors.muted : AppColors.ink;
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: Material(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              children: [
                Icon(icon, color: color),
                const SizedBox(height: AppSpacing.xs),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlapping blank avatars. Names stay hidden until visibility rules are
/// decided (open decision 4).
class _AvatarStack extends StatelessWidget {
  const _AvatarStack();

  @override
  Widget build(BuildContext context) {
    const size = 32.0, step = 22.0;
    return ExcludeSemantics(
      child: SizedBox(
        width: size + step * 2,
        height: size,
        child: Stack(
          children: [
            for (var i = 0; i < 3; i++)
              Positioned(
                left: i * step,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: AppColors.fill,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: const Icon(Icons.person_rounded, size: 18, color: AppColors.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
