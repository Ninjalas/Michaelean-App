import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/grades.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_header.dart';
import '../../widgets/fade_switch.dart';
import '../../widgets/filter_chips.dart';
import '../../widgets/pressable.dart';
import '../../widgets/segmented_pills.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/surface_card.dart';

/// The student's own grades by semester (spec §7.6): the overall average,
/// then Course · Units · Midterm · Final · Average. Read-only, only for the
/// student themselves.
class GradesScreen extends StatefulWidget {
  final CampusService campusService;

  const GradesScreen({super.key, required this.campusService});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  Future<List<SemesterGrades>>? _data;
  String? _loadedFor;
  int _semester = 0; // 0 = the current semester (newest first)

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (session.user != null && session.dataKey != _loadedFor) {
      _loadedFor = session.dataKey;
      _data = widget.campusService.loadGrades(session.user!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BackHeader('Grades'),
            Expanded(
              child: FutureBuilder<List<SemesterGrades>>(
                future: _data,
                builder: fadeOnLoad((context, snap) {
                  if (snap.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Couldn't load your grades."),
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton(
                            onPressed: () => setState(() {
                                _data = widget.campusService
                                    .loadGrades(SessionScope.of(context).user!);
                              }),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  final semesters = snap.data;
                  if (semesters == null) {
                    return const Align(
                        alignment: Alignment.topCenter, child: LinearProgressIndicator());
                  }
                  if (semesters.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.screen),
                      child: Text('No grades to show.', style: muted),
                    );
                  }
                  final sem = semesters[_semester.clamp(0, semesters.length - 1)];
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen, 0, AppSpacing.screen, 120),
                    children: [
                      FilterChips(
                        options: [
                          for (var i = 0; i < semesters.length; i++)
                            (i, _short(semesters[i].name)),
                        ],
                        selected: _semester,
                        onChanged: (i) => setState(() => _semester = i),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _Overall(sem, semester: semesters.indexOf(sem)),
                      const SizedBox(height: AppSpacing.lg),
                      SurfaceCard(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
                        child: _GradeTable(sem),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Sample grades, not official records. Passing grade: $passingGrade.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.muted),
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
}

/// "1st Semester 2025–2026" → "1st Sem 25–26", so three semesters fit on a phone.
String _short(String name) => name
    .replaceFirst('Semester', 'Sem')
    .replaceAllMapped(RegExp(r'20(\d\d)–20(\d\d)'), (m) => '${m[1]}–${m[2]}');

/// The semester's GWA on SMCL's 1.00–5.00 scale (big) with the percentage
/// average beside it, or why there isn't one yet.
class _Overall extends StatelessWidget {
  final SemesterGrades sem;
  final int semester; // its index, for the explanation sheet

  const _Overall(this.sem, {required this.semester});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.muted);
    final gwa = sem.gwa(AverageMethod.byUnits);
    final done = sem.finished.length;
    final all = sem.courses.length;
    // Tap to see how it's counted, once there's an average to explain.
    return Pressable(
      color: AppColors.white,
      shadow: AppColors.cardShadow,
      borderRadius: BorderRadius.circular(AppRadius.large),
      onTap: gwa == null ? null : () => context.push('/life/grades/average?sem=$semester'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(child: _numbers(text, muted, gwa, done, all)),
            if (gwa != null)
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _numbers(TextTheme text, TextStyle? muted, double? gwa, int done, int all) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GWA', style: muted),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(gwa == null ? '—' : gwa.toStringAsFixed(2),
                  style: text.headlineMedium?.copyWith(color: AppColors.navy)),
              if (gwa != null) ...[
                const SizedBox(width: AppSpacing.sm),
                // The same average in percent, smaller.
                Flexible(
                  child: Text('${sem.percent(AverageMethod.byUnits)!.toStringAsFixed(2)}%',
                      style: text.titleMedium?.copyWith(color: AppColors.muted)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            gwa == null
                ? 'Shows once a course has both grades.'
                : done == all
                    ? '$all courses · ${sem.finishedUnits} units'
                    : 'Based on $done of $all courses · ${sem.finishedUnits} units',
            style: muted,
          ),
        ],
      );
}

/// Course · Units · Midterm · Final · Average, the average with its SMCL
/// grade point under it. A grade not out yet is "—"; grades below passing
/// are red; a 4.00 is tagged Conditional fail, a 5.00 Failed.
class _GradeTable extends StatelessWidget {
  final SemesterGrades sem;

  const _GradeTable(this.sem);

  // Column widths: the course code gets the most room.
  static const _flex = [3, 2, 2, 2, 2];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final head = text.labelMedium?.copyWith(color: AppColors.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: _row(['Course', 'Units', 'Midterm', 'Final', 'Average'], head),
        ),
        for (final c in sem.courses) ...[
          const Divider(height: 1),
          Semantics(
            container: true, // one row at a time for screen readers
            label: '${c.code}, ${c.units} units, midterm ${_say(c.midterm)}, '
                'final ${_say(c.finalGrade)}, average ${_say(c.average)}'
                '${c.point == null ? '' : ', grade point ${c.point!.label}'}'
                '${c.point?.conditional ?? false ? ', conditional fail' : ''}'
                '${c.point?.failed ?? false ? ', failed' : ''}',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: _flex[0],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fit(Text(c.code, style: text.titleMedium)),
                        if (c.point?.conditional ?? false) ...[
                          const SizedBox(height: 2),
                          _fit(const StatusPill('Conditional fail', tone: PillTone.amber)),
                        ],
                        if (c.point?.failed ?? false) ...[
                          const SizedBox(height: 2),
                          _fit(const StatusPill('Failed', tone: PillTone.red)),
                        ],
                      ],
                    ),
                  ),
                  _cell(1, '${c.units}', text.bodyLarge),
                  _cell(2, _show(c.midterm), _gradeStyle(text.bodyLarge, c.midterm)),
                  _cell(3, _show(c.finalGrade), _gradeStyle(text.bodyLarge, c.finalGrade)),
                  _cell(4, _show(c.average),
                      _gradeStyle(text.bodyLarge, c.average)?.copyWith(fontWeight: FontWeight.w600),
                      sub: c.point?.label),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _row(List<String> labels, TextStyle? style) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              i == 0
                  ? Expanded(
                      flex: _flex[0],
                      child: _fit(Text(labels[i], style: style), align: Alignment.centerLeft),
                    )
                  : _cell(i, labels[i], style),
          ],
        ),
      );

  /// A centred number column (the average is right-aligned, at the edge),
  /// with an optional small line under it (the average's grade point).
  Widget _cell(int column, String value, TextStyle? style, {String? sub}) => Expanded(
        flex: _flex[column],
        child: Align(
          alignment: column == 4 ? Alignment.centerRight : Alignment.center,
          child: _fit(Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: style?.copyWith(fontFeatures: _digits)),
              if (sub != null)
                Text(sub,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.muted, fontFeatures: _digits)),
            ],
          )),
        ),
      );

  /// With large text, a cell shrinks to fit instead of overflowing.
  static Widget _fit(Widget child, {Alignment align = Alignment.center}) =>
      FittedBox(fit: BoxFit.scaleDown, alignment: align, child: child);

  static const _digits = [FontFeature.tabularFigures()]; // columns line up

  static String _show(int? grade) => grade?.toString() ?? '—';
  static String _say(int? grade) => grade?.toString() ?? 'not out yet';

  static TextStyle? _gradeStyle(TextStyle? base, int? grade) =>
      grade != null && grade < passingGrade ? base?.copyWith(color: AppColors.red) : base;
}

/// The pop-up behind the overall average (spec §7.6): a switch between
/// By units (GWA) and Simple average, and every step of the sum, from the
/// course averages as shown on the page.
class AverageSheet extends StatefulWidget {
  final CampusService campusService;
  final int semester; // index into loadGrades(), 0 = this semester

  const AverageSheet({super.key, required this.campusService, required this.semester});

  @override
  State<AverageSheet> createState() => _AverageSheetState();
}

class _AverageSheetState extends State<AverageSheet> {
  Future<List<SemesterGrades>>? _data;
  AverageMethod _method = AverageMethod.byUnits;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _data ??= widget.campusService.loadGrades(SessionScope.of(context).user!);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.muted);
    return FutureBuilder<List<SemesterGrades>>(
      future: _data,
      builder: fadeOnLoad((context, snap) {
        if (snap.hasError) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.screen),
            child: Text("Couldn't load your grades."),
          );
        }
        final semesters = snap.data;
        if (semesters == null) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.screen),
            child: LinearProgressIndicator(),
          );
        }
        if (widget.semester < 0 || widget.semester >= semesters.length) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Text('No grades to show.', style: muted),
          );
        }
        final sem = semesters[widget.semester];
        final done = sem.finished;
        final waiting = [for (final c in sem.courses) if (c.average == null) c.code];
        final byUnits = _method == AverageMethod.byUnits;
        // Points × units (or the points), from the grade points as shown.
        final total = done.fold(0.0, (sum, c) => sum + c.point!.point * (byUnits ? c.units : 1));
        final count = byUnits
            ? '${sem.finishedUnits} units'
            : '${done.length} ${done.length == 1 ? 'course' : 'courses'}';
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.screen),
          children: [
            Text(sem.name, style: muted),
            const SizedBox(height: AppSpacing.md),
            SegmentedPills<AverageMethod>(
              segments: [for (final m in AverageMethod.values) (m, m.label)],
              selected: _method,
              onChanged: (m) => setState(() => _method = m),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              byUnits
                  ? 'Each course average becomes its SMCL grade point. Courses with more '
                      'units count more: each point × its units, added up, ÷ the total units.'
                  : 'Each course average becomes its SMCL grade point. Every course counts '
                      'the same: the points added up, ÷ the number of courses.',
              style: muted,
            ),
            const SizedBox(height: AppSpacing.md),
            if (done.isEmpty)
              Text('No course has both grades yet, so there is no average to count.',
                  style: text.bodyLarge)
            else ...[
              for (final c in done)
                _line(
                  text,
                  c.code,
                  '${c.average} → ${c.point!.label}${byUnits ? ' × ${c.units}' : ''}',
                  (c.point!.point * (byUnits ? c.units : 1)).toStringAsFixed(2),
                ),
              const Divider(height: AppSpacing.lg),
              _line(text, 'Total', count, total.toStringAsFixed(2), bold: true),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.fill,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text('${total.toStringAsFixed(2)} ÷ $count', style: muted)),
                        Text(sem.gwa(_method)!.toStringAsFixed(2),
                            style: text.headlineSmall?.copyWith(color: AppColors.navy)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('In percent: ${sem.percent(_method)!.toStringAsFixed(2)}%',
                        style: muted),
                  ],
                ),
              ),
            ],
            if (waiting.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('Not counted yet (a grade isn’t out): ${waiting.join(', ')}.',
                  style: muted),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text('SMCL grading scale', style: text.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            for (var i = 0; i < smclScale.length; i++)
              _line(text, _range(i), smclScale[i].description, smclScale[i].label),
          ],
        );
      }),
    );
  }

  /// "99–100", "96–98", …, "Below 70" for step [i] of SMCL's scale.
  static String _range(int i) {
    final g = smclScale[i];
    if (g.minPercent == 0) return 'Below ${smclScale[i - 1].minPercent}';
    final top = i == 0 ? 100 : smclScale[i - 1].minPercent - 1;
    return '${g.minPercent}–$top';
  }

  /// "CS 201   90 → 1.75 × 3   5.25": the course, the working, the result.
  Widget _line(TextTheme text, String label, String? working, String result,
      {bool bold = false}) {
    final style = (bold ? text.titleMedium : text.bodyLarge)
        ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          // Wraps with large text instead of running off the edge.
          if (working != null)
            Flexible(
              child: Text(working,
                  textAlign: TextAlign.right, style: style?.copyWith(color: AppColors.muted)),
            ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 64), // results line up on the right
            child: Text(result, textAlign: TextAlign.right, style: style),
          ),
        ],
      ),
    );
  }
}
