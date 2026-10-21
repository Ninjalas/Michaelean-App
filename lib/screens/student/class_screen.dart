import 'dart:math';

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

/// A student's Class screen (spec §7.1), top to bottom: attendance this
/// semester (overall and by subject), the schedule with a day strip that
/// scrolls across the whole semester, and the records of the selected day.
/// Attendance counts finalized sessions only (spec §7.2).
class ClassScreen extends StatefulWidget {
  final CampusService campusService;

  const ClassScreen({super.key, required this.campusService});

  @override
  State<ClassScreen> createState() => _ClassScreenState();
}

class _ClassData {
  final List<DateTime> days; // every Mon–Sat class day of the semester
  final List<ClassSession> sessions; // the student's sessions this semester
  final List<AttendanceRecord> records; // finalized, newest first

  const _ClassData(this.days, this.sessions, this.records);
}

class _ClassScreenState extends State<ClassScreen> {
  static const _pillExtent = 56.0; // width of one day in the strip

  Future<_ClassData>? _data;
  String? _loadedFor; // Session.dataKey the data belongs to
  DateTime _selected = _dayOnly(DateTime.now());
  List<DateTime> _days = const [];
  ScrollController? _strip;

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (session.user != null && session.dataKey != _loadedFor) {
      _loadedFor = session.dataKey;
      _data = _load();
    }
  }

  @override
  void dispose() {
    _strip?.dispose();
    super.dispose();
  }

  Future<_ClassData> _load() async {
    final user = SessionScope.of(context).user!;
    final s = widget.campusService;
    final sem = await s.loadSemester(user);
    final (sessions, records) = await (
      s.loadSchedule(user, sem.start, sem.end.add(const Duration(days: 1))),
      s.loadMyAttendance(user),
    ).wait;
    final days = [
      for (var d = sem.start; !d.isAfter(sem.end); d = DateTime(d.year, d.month, d.day + 1))
        if (d.weekday != DateTime.sunday) d,
    ];
    // Start on today, or the nearest class day inside the semester.
    if (!days.contains(_selected)) {
      final today = _dayOnly(DateTime.now());
      _selected = days.firstWhere((d) => !d.isBefore(today), orElse: () => days.last);
    }
    _days = days;
    return _ClassData(days, sessions, records);
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
              child: FutureBuilder<_ClassData>(
                future: _data,
                builder: (context, snap) {
                  final data = snap.data;
                  if (snap.hasError) return _error();
                  if (data == null) {
                    return const Align(
                        alignment: Alignment.topCenter, child: LinearProgressIndicator());
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 120),
                    children: [
                      ..._attendance(data.records),
                      const SectionHeader('Schedule'),
                      _monthRow(),
                      const SizedBox(height: AppSpacing.sm),
                      _dayStrip(data.days),
                      ..._dayClasses(data.sessions),
                      const SectionHeader('Records'),
                      Text('${weekdayName(_selected)}, ${formatDayMonth(_selected)}',
                          style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                      ..._dayRecords(data.sessions, data.records),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Only finalized sessions count. Sample data, not official records.',
                          style: text.bodyMedium?.copyWith(color: AppColors.muted)),
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

  // ---------- Attendance this semester ----------

  List<Widget> _attendance(List<AttendanceRecord> records) {
    final text = Theme.of(context).textTheme;
    final title = Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
      child: Semantics(header: true, child: Text('Attendance', style: text.titleLarge)),
    );
    if (records.isEmpty) return [title, _muted('No finalized sessions yet.')];

    int presentIn(Iterable<AttendanceRecord> rs) =>
        rs.where((r) => r.mark == AttendanceMark.present).length;
    int pct(Iterable<AttendanceRecord> rs) => (presentIn(rs) * 100 / rs.length).round();
    final bySubject = <String, List<AttendanceRecord>>{};
    for (final r in records) {
      bySubject.putIfAbsent(r.session.subject, () => []).add(r);
    }

    return [
      title,
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${pct(records)}%', style: text.displaySmall?.copyWith(color: AppColors.navy)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                  'Present in ${presentIn(records)} of ${records.length} sessions this semester',
                  style: text.bodyMedium?.copyWith(color: AppColors.muted)),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      Text('By subject', style: text.labelMedium?.copyWith(color: AppColors.muted)),
      for (final e in bySubject.entries)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(child: Text(e.key, style: text.bodyLarge)),
              Text('${presentIn(e.value)} of ${e.value.length}',
                  style: text.bodyMedium?.copyWith(color: AppColors.muted)),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 48,
                child: Text('${pct(e.value)}%',
                    textAlign: TextAlign.right, style: text.titleMedium),
              ),
            ],
          ),
        ),
    ];
  }

  // ---------- Schedule ----------

  /// "October 2026" for the selected day, and a way back to today.
  Widget _monthRow() {
    final text = Theme.of(context).textTheme;
    final today = _dayOnly(DateTime.now());
    final month = formatDate(_selected).split(' ').skip(1).join(' '); // "October 2026"
    return Row(
      children: [
        Expanded(child: Text(month, style: text.titleMedium)),
        if (_selected != today && _days.contains(today))
          TextButton(
            onPressed: () => _select(today, scroll: true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.navy,
              minimumSize: const Size(48, 40),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            child: const Text('Today'),
          ),
      ],
    );
  }

  void _select(DateTime day, {bool scroll = false}) {
    final i = _days.indexOf(day);
    if (i < 0) return;
    setState(() => _selected = day);
    final strip = _strip;
    if (scroll && strip != null && strip.hasClients) {
      final target = i * _pillExtent - (strip.position.viewportDimension - _pillExtent) / 2;
      strip.animateTo(target.clamp(0, strip.position.maxScrollExtent),
          duration: AppMotion.slow, curve: AppMotion.curve);
    }
  }

  /// Every class day of the semester, scrolling sideways; opens centered on
  /// the selected day.
  Widget _dayStrip(List<DateTime> days) {
    final now = DateTime.now();
    return LayoutBuilder(builder: (context, box) {
      final i = max(0, days.indexOf(_selected));
      _strip ??= ScrollController(
          initialScrollOffset: max(0, i * _pillExtent - (box.maxWidth - _pillExtent) / 2));
      return SizedBox(
        height: 74,
        child: ListView.builder(
          key: const Key('day-strip'),
          controller: _strip,
          scrollDirection: Axis.horizontal,
          itemExtent: _pillExtent,
          itemCount: days.length,
          itemBuilder: (_, i) => _dayPill(days[i], now),
        ),
      );
    });
  }

  Widget _dayPill(DateTime day, DateTime now) {
    final selected = day == _selected;
    final isToday = _sameDay(day, now);
    final fg = selected ? AppColors.white : AppColors.ink;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Semantics(
        button: true,
        selected: selected,
        label: '${weekdayName(day)} ${formatDayMonth(day)}${isToday ? ', today' : ''}',
        excludeSemantics: true,
        child: InkWell(
          onTap: () => _select(day),
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

  List<ClassSession> _ofSelectedDay(List<ClassSession> sessions) =>
      sessions.where((c) => _sameDay(c.start, _selected)).toList();

  List<Widget> _dayClasses(List<ClassSession> sessions) {
    final day = _ofSelectedDay(sessions);
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

  // ---------- Records of the selected day ----------

  /// Each class of the selected day with its finalized mark, or why it has
  /// none yet. Unfinalized sessions never show a mark (spec §7.2).
  List<Widget> _dayRecords(List<ClassSession> sessions, List<AttendanceRecord> records) {
    final day = _ofSelectedDay(sessions);
    if (day.isEmpty) {
      return [const SizedBox(height: AppSpacing.sm), _muted('No classes, so no records.')];
    }
    final byId = {for (final r in records) r.session.id: r};
    final now = DateTime.now();
    return [
      for (var i = 0; i < day.length; i++) ...[
        if (i > 0) const Divider(height: 1),
        ContentRow(
          title: day[i].subject,
          meta: formatTime(day[i].start),
          metaIcon: Icons.schedule_rounded,
          pill: switch (byId[day[i].id]?.mark) {
            AttendanceMark.present => const StatusPill('Present', tone: PillTone.green),
            AttendanceMark.absent => const StatusPill('Absent', tone: PillTone.red),
            null => day[i].start.isAfter(now)
                ? const StatusPill('Upcoming')
                : const StatusPill('Not finalized yet'),
          },
        ),
      ],
    ];
  }

  Widget _muted(String s) => Text(s,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted));

  Widget _error() => Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
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
