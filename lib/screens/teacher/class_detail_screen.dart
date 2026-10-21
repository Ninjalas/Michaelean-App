import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/attendance.dart';
import '../../models/feed.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/back_header.dart';
import '../../widgets/content_row.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/user_avatar.dart';

/// One class, for its assigned teacher (spec §9.1): today's or the next
/// session with its attendance action, the roster, and recent sessions.
class ClassDetailScreen extends StatefulWidget {
  final CampusService campusService;
  final String classId;

  const ClassDetailScreen({super.key, required this.campusService, required this.classId});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  Future<ClassDetail?>? _detail;
  String? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (session.user != null && session.dataKey != _loadedFor) {
      _loadedFor = session.dataKey;
      _detail = widget.campusService.loadClassDetail(session.user!, widget.classId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<ClassDetail?>(
          future: _detail,
          builder: (context, snap) {
            final d = snap.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BackHeader(d?.info.subject ?? 'Class'),
                Expanded(
                  child: snap.hasError
                      ? const Center(child: Text("Couldn't load this class."))
                      : snap.connectionState != ConnectionState.done
                          ? const Align(
                              alignment: Alignment.topCenter, child: LinearProgressIndicator())
                          : d == null
                              ? Padding(
                                  padding: const EdgeInsets.all(AppSpacing.screen),
                                  child: Text("You can't manage this class.",
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

  Widget _content(ClassDetail d) {
    final text = Theme.of(context).textTheme;
    final info = d.info;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, 120),
      children: [
        Text('${info.section} · ${info.room}', style: text.bodyLarge),
        Text(
          '${info.weekdays.map(weekdayShort).join(' · ')}, '
          '${formatMinutesRange(info.startMinute, info.endMinute)}',
          style: text.bodyMedium?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SessionCard(session: d.current),
        SectionHeader('Roster (${d.roster.length})'),
        for (var i = 0; i < d.roster.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: 40 + AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
            child: Row(
              children: [
                UserAvatar(
                    name: d.roster[i].name, imageAsset: d.roster[i].photoAsset, size: 40),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(d.roster[i].name, style: text.bodyLarge)),
                Text(d.roster[i].maskedId,
                    style: text.bodyMedium?.copyWith(color: AppColors.muted)),
              ],
            ),
          ),
        ],
        const SectionHeader('Recent Sessions'),
        if (d.recent.isEmpty)
          Text('No past sessions yet.',
              style: text.bodyLarge?.copyWith(color: AppColors.muted))
        else
          for (var i = 0; i < d.recent.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _recentRow(d.recent[i]),
          ],
      ],
    );
  }

  Widget _recentRow(SessionSummary r) {
    final s = r.session;
    final now = DateTime.now();
    final (String meta, StatusPill pill) = s.finalized
        ? ('${r.present} present · ${r.total - r.present} absent',
            const StatusPill('Finalized', tone: PillTone.green))
        : s.awaitingFinalization
            ? ('${r.present} scanned · ${r.total - r.present} unchecked',
                const StatusPill('To finalize', tone: PillTone.amber))
            : ('No attendance taken', const StatusPill('Not taken'));
    return ContentRow(
      title: '${formatDayLabel(s.start, now)}, ${formatDayMonth(s.start)}',
      meta: meta,
      metaIcon: Icons.how_to_reg_outlined,
      pill: pill,
      onTap: s.awaitingFinalization ? () => context.push('/attendance/${s.id}/review') : null,
    );
  }
}

/// Today's (or the next) session and what the teacher can do with it now.
class _SessionCard extends StatelessWidget {
  final ClassSession? session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final s = session;
    final now = DateTime.now();
    final List<Widget> body;
    if (s == null) {
      body = [Text('No upcoming sessions.', style: text.bodyLarge)];
    } else {
      final ended = !s.end.isAfter(now);
      body = [
        Text(
          '${_sameDay(s.start, now) ? 'Today' : formatDayLabel(s.start, now)} · '
          '${formatTime(s.start)} – ${formatTime(s.end)}',
          style: text.titleMedium,
        ),
        Text(s.room, style: text.bodyMedium?.copyWith(color: AppColors.muted)),
        const SizedBox(height: AppSpacing.md),
        if (s.finalized)
          const Align(
            alignment: Alignment.centerLeft,
            child: StatusPill('Attendance finalized', tone: PillTone.green),
          )
        else if (s.awaitingFinalization)
          FilledButton(
            onPressed: () => context.push('/attendance/${s.id}/review'),
            child: const Text('Review & finalize'),
          )
        else if (ended)
          Text("Attendance wasn't taken for this session.",
              style: text.bodyMedium?.copyWith(color: AppColors.muted))
        else ...[
          FilledButton.icon(
            onPressed: () => context.push('/attendance/${s.id}'),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Start attendance'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () =>
                context.push('/life/classes/${s.classId}/edit?session=${s.id}'),
            child: const Text('Change this session'),
          ),
        ],
      ];
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screen),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: body),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
