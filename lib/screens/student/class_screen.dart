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

/// A student's Class screen (spec §7.1): Show QR, a Mon–Sat day strip with
/// that day's classes, and attendance from finalized records only (§7.2).
class ClassScreen extends StatefulWidget {
  final CampusService campusService;

  const ClassScreen({super.key, required this.campusService});

  @override
  State<ClassScreen> createState() => _ClassScreenState();
}

class _ClassScreenState extends State<ClassScreen> {
  Future<(List<ClassSession>, List<AttendanceRecord>)>? _data;
  String? _loadedFor; // Session.dataKey the data belongs to
  late DateTime _selected = _initialDay(DateTime.now());

  /// Today; on Sunday (no classes), the coming Monday.
  static DateTime _initialDay(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return today.weekday == DateTime.sunday ? today.add(const Duration(days: 1)) : today;
  }

  DateTime get _monday => _selected.subtract(Duration(days: _selected.weekday - 1));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (session.user != null && session.dataKey != _loadedFor) {
      _loadedFor = session.dataKey;
      _data = _load();
    }
  }

  Future<(List<ClassSession>, List<AttendanceRecord>)> _load() {
    final user = SessionScope.of(context).user!;
    return (
      widget.campusService
          .loadSchedule(user, _monday, _monday.add(const Duration(days: DateTime.saturday))),
      widget.campusService.loadMyAttendance(user),
    ).wait;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackHeader(
              'Class',
              trailing: FilledButton.icon(
                onPressed: () => context.push('/qr'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navyTint,
                  foregroundColor: AppColors.navy,
                  minimumSize: const Size(48, 44),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                label: const Text('Show QR'),
              ),
            ),
            Expanded(
              child: FutureBuilder(
                future: _data,
                builder: (context, snap) {
                  final data = snap.data;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 120),
                    children: [
                      _dayStrip(),
                      if (snap.hasError)
                        _error()
                      else if (data == null)
                        const Padding(
                          padding: EdgeInsets.only(top: AppSpacing.section),
                          child: LinearProgressIndicator(),
                        )
                      else ...[
                        ..._dayClasses(data.$1),
                        ..._attendance(data.$2),
                        const SizedBox(height: AppSpacing.lg),
                        Text('Only finalized sessions count. Sample data, not official records.',
                            style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayStrip() {
    final now = DateTime.now();
    return Row(
      children: [
        for (var i = 0; i < 6; i++)
          Expanded(child: _dayPill(_monday.add(Duration(days: i)), now)),
      ],
    );
  }

  Widget _dayPill(DateTime day, DateTime now) {
    final selected = _sameDay(day, _selected);
    final isToday = _sameDay(day, now);
    final fg = selected ? AppColors.white : AppColors.ink;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Semantics(
        button: true,
        selected: selected,
        label: '${weekdayName(day)} ${day.day}${isToday ? ', today' : ''}',
        excludeSemantics: true,
        child: InkWell(
          onTap: () => setState(() => _selected = day), // same week: no reload needed
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.curve,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: selected ? AppColors.navy : AppColors.fill,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Column(
              children: [
                Text(weekdayShort(day.weekday),
                    style: TextStyle(fontSize: 12, color: selected ? fg : AppColors.muted)),
                const SizedBox(height: 2),
                Text('${day.day}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg)),
                // Small dot marks today when another day is selected.
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isToday && !selected ? AppColors.navy : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _dayClasses(List<ClassSession> week) {
    final day = week.where((c) => _sameDay(c.start, _selected)).toList();
    if (day.isEmpty) {
      return [
        const SizedBox(height: AppSpacing.lg),
        _muted('No classes on ${weekdayName(_selected)}.'),
      ];
    }
    return [
      const SizedBox(height: AppSpacing.sm),
      for (var i = 0; i < day.length; i++) ...[
        if (i > 0) const Divider(height: 1),
        ContentRow(
          source: '${formatTime(day[i].start)} – ${formatTime(day[i].end)}',
          title: day[i].subject,
          meta: [day[i].room, if (day[i].teacher != null) day[i].teacher!].join(' · '),
          metaIcon: Icons.place_outlined,
        ),
      ],
    ];
  }

  List<Widget> _attendance(List<AttendanceRecord> records) {
    final text = Theme.of(context).textTheme;
    if (records.isEmpty) {
      return [const SectionHeader('Attendance'), _muted('No finalized sessions yet.')];
    }
    int pct(Iterable<AttendanceRecord> rs) =>
        (rs.where((r) => r.mark == AttendanceMark.present).length * 100 / rs.length).round();
    final bySubject = <String, List<AttendanceRecord>>{};
    for (final r in records) {
      bySubject.putIfAbsent(r.session.subject, () => []).add(r);
    }
    final present = records.where((r) => r.mark == AttendanceMark.present).length;
    return [
      const SectionHeader('Attendance'),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${pct(records)}%',
              style: text.displaySmall?.copyWith(color: AppColors.navy)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('Present in $present of ${records.length} sessions',
                  style: text.bodyMedium?.copyWith(color: AppColors.muted)),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      for (final e in bySubject.entries)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(e.key, style: text.bodyLarge)),
                  Text('${pct(e.value)}%', style: text.titleMedium),
                ],
              ),
              const SizedBox(height: AppSpacing.xs + 2),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: pct(e.value) / 100,
                  minHeight: 5,
                  backgroundColor: AppColors.fill,
                  color: AppColors.navy,
                  semanticsLabel: '${e.key} attendance',
                ),
              ),
            ],
          ),
        ),
      const SectionHeader('Recent Records'),
      for (var i = 0; i < records.take(6).length; i++) ...[
        if (i > 0) const Divider(height: 1),
        ContentRow(
          title: records[i].session.subject,
          meta: '${formatDayLabel(records[i].session.start, DateTime.now())} · '
              '${formatTime(records[i].session.start)}',
          metaIcon: Icons.calendar_today_outlined,
          pill: records[i].mark == AttendanceMark.present
              ? const StatusPill('Present', tone: PillTone.green)
              : const StatusPill('Absent', tone: PillTone.red),
        ),
      ],
    ];
  }

  Widget _muted(String s) => Text(s,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted));

  Widget _error() => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.section),
        child: Column(
          children: [
            const Text("Couldn't load your classes."),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => setState(() => _data = _load()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
