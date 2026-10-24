import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/event_record.dart';
import '../../models/feed.dart';
import '../../models/people.dart';
import '../../models/user_profile.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_rows.dart';
import '../../widgets/content_row.dart';
import '../../widgets/fade_switch.dart';
import '../../widgets/person_row.dart';
import '../../widgets/round_icon_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/tab_reselect.dart';
import '../../widgets/user_avatar.dart';
import 'event_history_screen.dart';

/// Shared social-identity profile for both roles, in Luma's profile layout
/// (spec §10). No QR here: it lives on the long-press sheet (spec §1.3).
class ProfileScreen extends StatefulWidget {
  final UserService userService;
  final CampusService campusService;

  const ProfileScreen({super.key, required this.userService, required this.campusService});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileData {
  final List<EventRecord> history;
  final int orgCount; // students
  final ConnectionsOverview? connections; // students (spec §10.1)
  final List<ClassSession> teaching; // teachers: one entry per class taught

  const _ProfileData({
    required this.history,
    this.orgCount = 0,
    this.connections,
    this.teaching = const [],
  });
}

/// The pill tone for an identity tag; shared with other people's profiles.
PillTone tagTone(TagKind k) => switch (k) {
      TagKind.institution || TagKind.school || TagKind.department => PillTone.navy,
      TagKind.organization => PillTone.neutral,
      TagKind.officer => PillTone.red,
      TagKind.role => PillTone.green,
    };

class _ProfileScreenState extends State<ProfileScreen> {
  final _scroll = ScrollController();
  Future<_ProfileData>? _data;
  String? _loadedFor; // Session.dataKey the data belongs to
  bool _busy = false; // answering or cancelling a request

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when the previewed account changes (role switch in Settings).
    final user = SessionScope.of(context).user;
    if (user != null && SessionScope.of(context).dataKey != _loadedFor) {
      _loadedFor = SessionScope.of(context).dataKey;
      _data = _load(user);
    }
  }

  Future<_ProfileData> _load(UserProfile user) async {
    if (user.role == UserRole.student) {
      final (history, orgs, connections) = await (
        widget.campusService.loadEventHistory(user),
        widget.campusService.loadMyOrganizations(user),
        widget.campusService.loadConnections(user),
      ).wait;
      return _ProfileData(history: history, orgCount: orgs.length, connections: connections);
    }
    final (history, classes) = await (
      widget.campusService.loadEventHistory(user),
      widget.campusService.loadClasses(user),
    ).wait;
    // The schedule repeats a class on several days; list each class once.
    final seen = <String>{};
    final teaching = [
      for (final c in classes)
        if (seen.add('${c.subject}|${c.section}')) c,
    ];
    return _ProfileData(history: history, teaching: teaching);
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionScope.of(context).user;
    if (user == null) return const SizedBox.shrink(); // preview just ended
    final text = Theme.of(context).textTheme;
    final isTeacher = user.role == UserRole.teacher;

    return SafeArea(
      bottom: false,
      child: FutureBuilder<_ProfileData>(
        future: _data,
        builder: (context, snap) {
          final data = snap.data;
          // Tapping Profile again glides back to the top.
          return ScrollToTopOnTabTap(
            tab: 2,
            controller: _scroll,
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen, AppSpacing.md, AppSpacing.screen, 120),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserAvatar(name: user.fullName, imageAsset: user.photoAsset, size: 96),
                    const Spacer(),
                    RoundIconButton(
                      icon: Icons.settings_outlined,
                      tooltip: 'Settings',
                      onPressed: () => context.push('/profile/settings'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(user.fullName, style: text.displaySmall),
                const SizedBox(height: AppSpacing.xs),
                Text('${isTeacher ? 'Teacher' : 'Student'} · ${user.designation}',
                    style: text.bodyLarge),
                Text('ID ${user.maskedId}',
                    style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                const SizedBox(height: AppSpacing.md),
                // Inline stats, counted from the loaded records (never typed in).
                SizedBox(
                  height: 24,
                  child: data == null ? null : _stats(data, isTeacher),
                ),
                const SizedBox(height: AppSpacing.md),
                // Official tags: assigned by the school, not editable here (spec §5).
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [for (final t in user.tags) StatusPill(t.label, tone: tagTone(t.kind))],
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () => context.push('/profile/edit'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.fill,
                    foregroundColor: AppColors.ink,
                  ),
                  child: const Text('Edit Profile'),
                ),
                if (user.about != null) ...[
                  const SectionHeader('About'),
                  Text(user.about!, style: text.bodyLarge),
                ],
                // The progress bar fades into the sections (spec §2.5).
                FadeSwitch(
                  loaded: data != null || snap.hasError,
                  child: snap.hasError
                      ? _error()
                      : data == null
                          ? const Padding(
                              padding: EdgeInsets.only(top: AppSpacing.section),
                              child: LinearProgressIndicator(),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (data.connections != null) ..._connections(data.connections!),
                                if (isTeacher) ...[
                                  const SectionHeader('Classes I Teach'),
                                  if (data.teaching.isEmpty)
                                    _muted('No classes assigned.')
                                  else
                                    ..._divided([
                                      for (final c in data.teaching)
                                        ContentRow(
                                          source: c.section,
                                          title: c.subject,
                                          meta: c.room,
                                          metaIcon: Icons.place_outlined,
                                          onTap: () => context.push('/profile/classes/${c.classId}'),
                                        ),
                                    ]),
                                ],
                                const SectionHeader('Event History'),
                                if (data.history.isEmpty)
                                  _muted('No recorded events yet.')
                                else
                                  ..._divided(indent: ContentRow.textIndent, [
                                    for (final e in data.history) eventRecordRow(context, e),
                                  ]),
                              ],
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// "3 Attended · 2 Orgs" (students) or "3 Classes · 1 Hosted" (teachers).
  Widget _stats(_ProfileData d, bool isTeacher) {
    final stats = isTeacher
        ? [
            (d.teaching.length, 'Classes'),
            // Only events whose record names this person as host (spec §10).
            (d.history.where((e) => e.role == EventRole.host).length, 'Hosted'),
          ]
        : [(d.history.length, 'Attended'), (d.orgCount, 'Orgs')];
    final text = Theme.of(context).textTheme;
    return Text.rich(
      TextSpan(
        style: text.bodyLarge?.copyWith(color: AppColors.muted),
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) const TextSpan(text: '  ·  '),
            TextSpan(
              text: '${stats[i].$1} ',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
            TextSpan(text: stats[i].$2),
          ],
        ],
      ),
    );
  }

  Widget _muted(String s) => Text(s,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted));

  List<Widget> _divided(List<Widget> rows, {double indent = 0}) => [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) Divider(height: 1, indent: indent),
          rows[i],
        ],
      ];

  Widget _error() => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.section),
        child: Column(
          children: [
            const Text("Couldn't load your profile details."),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => setState(() => _data = _load(SessionScope.of(context).user!)),
              child: const Text('Retry'),
            ),
          ],
        ),
      );

  /// Answers or cancels a request, then reloads and says what happened.
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
    session.refresh();
    messenger.showSnackBar(SnackBar(content: Text(done)));
  }

  /// Connections (spec §10.1): requests to answer, connections, requests sent.
  List<Widget> _connections(ConnectionsOverview c) {
    final s = widget.campusService;
    final label = Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.muted);
    void open(PersonSummary p) => context.push('/profile/people/${p.id}');
    Widget group(String title) => Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Text(title, style: label),
        );
    return [
      SectionHeader('Connections (${c.connections.length})'),
      if (c.incoming.isNotEmpty) ...[
        group('Requests (${c.incoming.length})'),
        AnimatedRows(
          separator: const Divider(height: 1, indent: PersonRow.textIndent),
          children: [
            for (final p in c.incoming)
              PersonRow(
                key: ValueKey(p.id),
                person: p,
                onTap: () => open(p),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Decline ${p.name}',
                      onPressed: _busy
                          ? null
                          : () => _act((me) => s.answerConnectRequest(me, p.id, accept: false),
                              "Request declined. They aren't told."),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    IconButton.filled(
                      tooltip: 'Accept ${p.name}',
                      onPressed: _busy
                          ? null
                          : () => _act((me) => s.answerConnectRequest(me, p.id, accept: true),
                              'Connected in this preview only.'),
                      icon: const Icon(Icons.check_rounded),
                    ),
                  ],
                ),
              ),
          ],
        ),
        group('Your connections'),
      ],
      if (c.connections.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: _muted('No connections yet. Find people in Student Life.'),
        )
      else
        AnimatedRows(
          separator: const Divider(height: 1, indent: PersonRow.textIndent),
          children: [
            for (final p in c.connections) PersonRow(key: ValueKey(p.id), person: p, onTap: () => open(p)),
          ],
        ),
      if (c.sent.isNotEmpty) ...[
        group('Sent'),
        AnimatedRows(
          separator: const Divider(height: 1, indent: PersonRow.textIndent),
          children: [
            for (final p in c.sent)
              PersonRow(
                key: ValueKey(p.id),
                person: p,
                onTap: () => open(p),
                trailing: TextButton(
                  onPressed: _busy
                      ? null
                      : () => _act((me) => s.cancelConnectRequest(me, p.id), 'Request cancelled.'),
                  child: const Text('Cancel'),
                ),
              ),
          ],
        ),
      ],
    ];
  }
}
