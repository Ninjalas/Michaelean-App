import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/people.dart';
import '../../models/user_profile.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_rows.dart';
import '../../widgets/back_header.dart';
import '../../widgets/fade_switch.dart';
import '../../widgets/person_row.dart';
import '../../widgets/segmented_pills.dart';

/// Settings › Privacy (spec §10.1): who may see your upcoming events, event
/// history, and connections, and the students you blocked. Saved in this
/// preview only.
class PrivacyScreen extends StatefulWidget {
  final CampusService campusService;

  const PrivacyScreen({super.key, required this.campusService});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  Future<(PrivacySettings, List<PersonSummary>)>? _data;
  String? _loadedFor;
  PrivacySettings? _settings; // what's shown; changes save right away
  bool _busy = false;

  static const _levels = [
    (PrivacyLevel.public, 'Public'),
    (PrivacyLevel.connections, 'Connections'),
    (PrivacyLevel.onlyMe, 'Only me'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (session.user != null && session.dataKey != _loadedFor) {
      _loadedFor = session.dataKey;
      final me = session.user!;
      _data = (widget.campusService.loadPrivacy(me), widget.campusService.loadBlocked(me))
          .wait
          .then((r) {
        _settings = r.$1;
        return r;
      });
    }
  }

  Future<void> _save(PrivacySettings next) async {
    final messenger = ScaffoldMessenger.of(context);
    final before = _settings!;
    setState(() => _settings = next);
    try {
      await widget.campusService.savePrivacy(SessionScope.of(context).user!, next);
    } catch (_) {
      // Say so, and put the choice back: it wasn't saved.
      if (mounted) setState(() => _settings = before);
      messenger.showSnackBar(const SnackBar(content: Text("Couldn't save this setting.")));
    }
  }

  Future<void> _unblock(PersonSummary p) async {
    final session = SessionScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await widget.campusService.unblockStudent(session.user!, p.id);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text("Couldn't unblock. Try again.")));
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    session.refresh();
    messenger.showSnackBar(SnackBar(content: Text('${p.name} unblocked in this preview only.')));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.muted);
    final isStudent = SessionScope.of(context).user?.role == UserRole.student;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BackHeader('Privacy'),
            Expanded(
              child: !isStudent
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.screen),
                      child: Text('Privacy settings are for students.',
                          style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                    )
                  : FutureBuilder<(PrivacySettings, List<PersonSummary>)>(
                      future: _data,
                      builder: fadeOnLoad((context, snap) {
                        if (snap.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(AppSpacing.screen),
                            child: Text("Couldn't load your privacy settings.",
                                style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                          );
                        }
                        final s = _settings;
                        if (s == null || !snap.hasData) {
                          return const Align(
                              alignment: Alignment.topCenter,
                              child: LinearProgressIndicator());
                        }
                        final blocked = snap.data!.$2;
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 120),
                          children: [
                            Text('Who can see these on your profile', style: muted),
                            _setting(
                              'Upcoming events',
                              'Events you are going to.',
                              s.upcomingEvents,
                              (v) => _save(s.copyWith(upcomingEvents: v)),
                            ),
                            _setting(
                              'Event history',
                              'Past events you attended.',
                              s.eventHistory,
                              (v) => _save(s.copyWith(eventHistory: v)),
                            ),
                            _setting(
                              'Connections',
                              'The list of people you are connected with.',
                              s.connections,
                              (v) => _save(s.copyWith(connections: v)),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                                'Your name, photo, section, tags, and About are always shown. '
                                'Saved in this preview only.',
                                style: muted),
                            const SizedBox(height: AppSpacing.section),
                            Text('Blocked students', style: text.titleMedium),
                            const SizedBox(height: AppSpacing.xs),
                            if (blocked.isEmpty)
                              Text("You haven't blocked anyone.", style: muted)
                            else
                              // Unblocked students fold away (spec §2.5).
                              AnimatedRows(
                                separator: const Divider(height: 1, indent: PersonRow.textIndent),
                                children: [
                                  for (final b in blocked)
                                    PersonRow(
                                      key: ValueKey(b.id),
                                      person: b,
                                      onTap: () => context.push('/profile/people/${b.id}'),
                                      trailing: TextButton(
                                        onPressed: _busy ? null : () => _unblock(b),
                                        child: const Text('Unblock'),
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        );
                      }),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _setting(
      String title, String help, PrivacyLevel value, ValueChanged<PrivacyLevel> onChanged) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleMedium),
          Text(help, style: text.bodyMedium?.copyWith(color: AppColors.muted)),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label: '$title: who can see it',
            child: SegmentedPills<PrivacyLevel>(
              segments: _levels,
              selected: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
