import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/event_record.dart';
import '../../models/feed.dart';
import '../../models/user_profile.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/content_row.dart';
import '../../widgets/round_icon_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/user_avatar.dart';

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
  final List<ClassSession> teaching; // teachers: one entry per class taught

  const _ProfileData({required this.history, this.orgCount = 0, this.teaching = const []});
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<_ProfileData>? _data;
  String? _loadedFor; // Session.dataKey the data belongs to

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
      final (history, orgs) = await (
        widget.userService.loadEventHistory(user),
        widget.campusService.loadMyOrganizations(user),
      ).wait;
      return _ProfileData(history: history, orgCount: orgs.length);
    }
    final (history, classes) = await (
      widget.userService.loadEventHistory(user),
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

  void _openSoon(String what) => context
      .push(Uri(path: '/profile/soon', queryParameters: {'what': what}).toString());

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
          return ListView(
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
                children: [for (final t in user.tags) StatusPill(t.label, tone: _tone(t.kind))],
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
              if (snap.hasError)
                _error()
              else if (data == null)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.section),
                  child: LinearProgressIndicator(),
                )
              else ...[
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
                          onTap: () => context.go('/life/classes/${c.classId}'),
                        ),
                    ]),
                ],
                const SectionHeader('Event History'),
                if (data.history.isEmpty)
                  _muted('No recorded events yet.')
                else
                  ..._divided(indent: ContentRow.textIndent, [
                    for (final e in data.history)
                      ContentRow(
                        title: e.eventName,
                        meta: '${formatDate(e.date)} · ${_roleLabel(e.role)}',
                        metaIcon: Icons.calendar_today_outlined,
                        imageAsset: e.imageAsset,
                        placeholderIcon: Icons.event_outlined,
                        pill: StatusPill(_statusLabel(e.status), tone: PillTone.green),
                        onTap: () => _openSoon(e.eventName),
                      ),
                  ]),
              ],
            ],
          );
        },
      ),
    );
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

  PillTone _tone(TagKind k) => switch (k) {
        TagKind.institution || TagKind.school || TagKind.department => PillTone.navy,
        TagKind.organization => PillTone.neutral,
        TagKind.officer => PillTone.red,
      };

  String _statusLabel(ParticipationStatus s) => switch (s) {
        ParticipationStatus.attended => 'Attended',
        ParticipationStatus.participated => 'Participated',
      };

  String _roleLabel(EventRole r) => switch (r) {
        EventRole.participant => 'Participant',
        EventRole.organizer => 'Organizer',
        EventRole.host => 'Host',
        EventRole.volunteer => 'Volunteer',
      };
}
