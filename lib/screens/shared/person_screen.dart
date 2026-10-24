import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/people.dart';
import '../../models/user_profile.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../utils/tab_path.dart';
import '../../widgets/back_header.dart';
import '../../widgets/content_row.dart';
import '../../widgets/fade_switch.dart';
import '../../widgets/person_row.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/user_avatar.dart';
import 'profile_screen.dart' show tagTone;

/// Another student's profile (spec §10.1), in the same layout as Profile.
/// What shows follows their privacy settings; teachers see everything and
/// get no Connect buttons. Opened from Student Life, Profile, or attendance
/// review; its links stay under whichever page opened it.
class PersonScreen extends StatefulWidget {
  final CampusService campusService;
  final String personId;

  const PersonScreen({super.key, required this.campusService, required this.personId});

  @override
  State<PersonScreen> createState() => _PersonScreenState();
}

class _PersonScreenState extends State<PersonScreen> {
  Future<PersonProfile?>? _data;
  String? _loadedFor; // Session.dataKey the data belongs to
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (session.user != null && session.dataKey != _loadedFor) {
      _loadedFor = session.dataKey;
      _data = widget.campusService.loadPerson(session.user!, widget.personId);
    }
  }

  /// The page this profile was opened from, e.g. "/life" or an attendance
  /// review: other profiles open under it.
  String get _base {
    final path = GoRouterState.of(context).uri.path;
    return path.substring(0, path.lastIndexOf('/people/'));
  }

  Future<void> _act(Future<void> Function(UserProfile me) action, String done) async {
    final session = SessionScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action(session.user!);
    } on StateError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Not done. ${e.message}')));
      return;
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text("Not done. Couldn't reach the service.")));
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    session.refresh(); // this page, Profile, and the bell reload
    messenger.showSnackBar(SnackBar(content: Text(done)));
  }

  Future<bool> _confirm(String title, String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.red),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _remove(PersonSummary p) async {
    if (!await _confirm('Remove ${p.name}?',
        "You'll no longer be connected. They aren't told.", 'Remove')) {
      return;
    }
    await _act((me) => widget.campusService.removeConnection(me, p.id),
        "Connection removed in this preview only. They aren't told.");
  }

  Future<void> _block(PersonSummary p) async {
    if (!await _confirm(
        'Block ${p.name}?',
        "You won't see each other's profiles, and they can't find you or send you "
            'requests. Any connection or request between you is removed.',
        'Block')) {
      return;
    }
    await _act((me) => widget.campusService.blockStudent(me, p.id),
        'Blocked in this preview only. You can unblock them here.');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<PersonProfile?>(
          future: _data,
          builder: (context, snap) {
            final p = snap.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BackHeader(p?.person.name ?? 'Profile',
                    trailing: p == null ? null : _moreMenu(p)),
                Expanded(
                  child: FadeSwitch(
                    loaded: snap.hasData || snap.hasError || snap.connectionState == ConnectionState.done,
                    child: snap.hasError
                        ? const Center(child: Text("Couldn't load this profile."))
                        : !snap.hasData && snap.connectionState != ConnectionState.done
                            ? const Align(
                                alignment: Alignment.topCenter, child: LinearProgressIndicator())
                            : p == null
                                ? Padding(
                                    padding: const EdgeInsets.all(AppSpacing.screen),
                                    child: Text("This profile isn't available.",
                                        style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                                  )
                                : _content(p),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Remove and Block, for students looking at another student.
  Widget? _moreMenu(PersonProfile p) {
    final me = SessionScope.of(context).user!;
    if (me.role != UserRole.student || me.id == p.person.id || p.limited) return null;
    return PopupMenuButton<String>(
      tooltip: 'More options',
      enabled: !_busy,
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: (v) => v == 'remove' ? _remove(p.person) : _block(p.person),
      itemBuilder: (context) => [
        if (p.person.status == ConnectionStatus.connected)
          const PopupMenuItem(value: 'remove', child: Text('Remove connection')),
        const PopupMenuItem(
            value: 'block', child: Text('Block', style: TextStyle(color: AppColors.red))),
      ],
    );
  }

  Widget _content(PersonProfile p) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.muted);
    final me = SessionScope.of(context).user!;
    final name = p.person.name;
    final first = name.split(' ').first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 120),
      children: [
        // Align keeps the round photo its own size (list items fill the width).
        Align(
          alignment: Alignment.centerLeft,
          child: UserAvatar(name: name, imageAsset: p.limited ? null : p.person.photoAsset, size: 96),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(name, style: text.displaySmall),
        if (p.limited) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
              p.person.status == ConnectionStatus.blocked
                  ? "You blocked $first. You don't see each other's profiles."
                  : "This profile isn't available.",
              style: text.bodyLarge?.copyWith(color: AppColors.muted)),
          if (p.person.status == ConnectionStatus.blocked) ...[
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => _act((me) => widget.campusService.unblockStudent(me, p.person.id),
                      'Unblocked in this preview only.'),
              child: const Text('Unblock'),
            ),
          ],
        ] else ...[
          const SizedBox(height: AppSpacing.xs),
          Text('Student · ${p.person.section}', style: text.bodyLarge),
          Text('ID ${p.maskedId}', style: muted),
          const SizedBox(height: AppSpacing.md),
          Text.rich(
            TextSpan(
              style: text.bodyLarge?.copyWith(color: AppColors.muted),
              children: [
                TextSpan(
                  text: '${p.connectionCount} ',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
                ),
                TextSpan(text: p.connectionCount == 1 ? 'Connection' : 'Connections'),
                if (p.mutualConnections.isNotEmpty) ...[
                  const TextSpan(text: '  ·  '),
                  TextSpan(
                    text: '${p.mutualConnections.length} ',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
                  ),
                  const TextSpan(text: 'Mutual'),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [for (final t in p.tags) StatusPill(t.label, tone: tagTone(t.kind))],
          ),
          if (me.id == p.person.id) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('This is you. Others see only what your privacy settings allow.', style: muted),
          ] else if (me.role == UserRole.student) ...[
            const SizedBox(height: AppSpacing.lg),
            _actions(p.person),
          ],
          if (p.about != null) ...[
            const SectionHeader('About'),
            Text(p.about!, style: text.bodyLarge),
          ],
          if (p.mutualConnections.isNotEmpty) ...[
            const SectionHeader('Mutual Connections'),
            ..._people(p.mutualConnections),
          ],
          const SectionHeader('Going To'),
          if (p.upcoming == null)
            _hidden(first)
          else if (p.upcoming!.isEmpty)
            _muted('No upcoming events.')
          else
            ..._divided(indent: ContentRow.textIndent, [
              for (final e in p.upcoming!)
                ContentRow(
                  source: '${formatDayLabel(e.start, DateTime.now())} · ${formatTime(e.start)}',
                  title: e.title,
                  meta: e.venue,
                  metaIcon: Icons.place_outlined,
                  imageAsset: e.coverAsset,
                  placeholderIcon: Icons.event_outlined,
                  onTap: _eventPath(e.id) == null ? null : () => context.push(_eventPath(e.id)!),
                ),
            ]),
          const SectionHeader('Event History'),
          if (p.history == null)
            _hidden(first)
          else if (p.history!.isEmpty)
            _muted('No recorded events yet.')
          else
            ..._divided(indent: ContentRow.textIndent, [
              for (final r in p.history!)
                ContentRow(
                  title: r.eventName,
                  meta: '${formatDate(r.date)} · ${r.role.label}',
                  metaIcon: Icons.calendar_today_outlined,
                  imageAsset: r.imageAsset,
                  placeholderIcon: Icons.event_outlined,
                  pill: StatusPill(r.status.label, tone: PillTone.green),
                  onTap: _eventPath(r.eventId) == null
                      ? null
                      : () => context.push(_eventPath(r.eventId)!),
                ),
            ]),
          const SectionHeader('Connections'),
          if (p.connections == null)
            _hidden(first)
          else if (p.connections!.isEmpty)
            _muted('No connections yet.')
          else
            ..._people(p.connections!),
        ],
      ],
    );
  }

  /// The event page in this tab; none over attendance review, which sits
  /// above the tabs.
  String? _eventPath(String eventId) =>
      _base.startsWith('/attendance') ? null : inTab(context, '/life/events/$eventId');

  /// The main button(s) for where you stand with them.
  Widget _actions(PersonSummary p) {
    final s = widget.campusService;
    return StateFade(
      state: p.status,
      child: switch (p.status) {
        ConnectionStatus.none => FilledButton.icon(
            onPressed: _busy
                ? null
                : () => _act((me) => s.sendConnectRequest(me, p.id),
                    'Request sent in this preview only.'),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Connect'),
          ),
        ConnectionStatus.requestSent => OutlinedButton(
            onPressed: _busy
                ? null
                : () => _act((me) => s.cancelConnectRequest(me, p.id), 'Request cancelled.'),
            child: const Text('Pending · Cancel request'),
          ),
        ConnectionStatus.requestReceived => Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _act((me) => s.answerConnectRequest(me, p.id, accept: false),
                          "Request declined. They aren't told."),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _act((me) => s.answerConnectRequest(me, p.id, accept: true),
                          'Connected in this preview only.'),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ConnectionStatus.connected => OutlinedButton.icon(
            onPressed: null, // remove lives in the ⋯ menu, so it isn't tapped by accident
            icon: const Icon(Icons.check_rounded),
            label: const Text('Connected'),
          ),
        ConnectionStatus.blocked => const SizedBox.shrink(), // shown as a limited profile
      },
    );
  }

  List<Widget> _people(List<PersonSummary> people) => _divided(indent: PersonRow.textIndent, [
        for (final q in people)
          PersonRow(person: q, onTap: () => context.push('$_base/people/${q.id}')),
      ]);

  Widget _hidden(String first) => _muted("Hidden by $first's privacy settings.");

  Widget _muted(String s) => Text(s,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted));

  List<Widget> _divided(List<Widget> rows, {double indent = 0}) => [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) Divider(height: 1, indent: indent),
          rows[i],
        ],
      ];
}
