/// A student's grades (spec §7.6). Grades are whole numbers; 75 passes.
library;

const passingGrade = 75;

/// One step of SMCL's grading scale: a percentage from [minPercent] up
/// converts to [point] (spec §7.6).
class GradePoint {
  final int minPercent;
  final double point; // 1.00 best … 5.00 failed
  final String description;

  const GradePoint(this.minPercent, this.point, this.description);

  bool get conditional => point == 4.0; // 70–74: Conditional Fail
  bool get failed => point == 5.0; // below 70

  /// "1.75"
  String get label => point.toStringAsFixed(2);
}

/// SMCL's grading scale, best first (spec §7.6). shortcut: one fixed table
/// in the app; the registrar's official table comes from the backend later.
const smclScale = [
  GradePoint(99, 1.00, 'Excellent'),
  GradePoint(96, 1.25, 'Superior'),
  GradePoint(93, 1.50, 'Very Good'),
  GradePoint(90, 1.75, 'Good'),
  GradePoint(87, 2.00, 'Very Satisfactory'),
  GradePoint(84, 2.25, 'Satisfactory'),
  GradePoint(81, 2.50, 'Fair / Average'),
  GradePoint(78, 2.75, 'Low Pass'),
  GradePoint(75, 3.00, 'Barely Passing'),
  GradePoint(70, 4.00, 'Conditional Fail'),
  GradePoint(0, 5.00, 'Failed'),
];

/// The grade point for a whole-number percentage, e.g. 90 → 1.75.
GradePoint gradePointFor(int percent) => smclScale.firstWhere((g) => percent >= g.minPercent);

/// One course in a semester. A grade that isn't out yet is null.
class CourseGrade {
  final String code; // e.g. "CS 302"
  final int units;
  final int? midterm;
  final int? finalGrade;

  const CourseGrade({required this.code, required this.units, this.midterm, this.finalGrade});

  /// (midterm + final) ÷ 2, rounded to a whole number (90.5 → 91); null
  /// until both grades are out.
  int? get average =>
      midterm == null || finalGrade == null ? null : ((midterm! + finalGrade!) / 2).round();

  /// The average's SMCL grade point; null until the average is out.
  GradePoint? get point => average == null ? null : gradePointFor(average!);
}

/// How the overall average is counted (spec §7.6).
enum AverageMethod {
  byUnits('By units (GWA)'),
  simple('Simple average');

  final String label;
  const AverageMethod(this.label);
}

/// One semester's courses, and its overall averages.
class SemesterGrades {
  final String name; // e.g. "1st Semester 2026–2027"
  final List<CourseGrade> courses;

  const SemesterGrades({required this.name, required this.courses});

  /// Courses with both grades out: the only ones the averages count.
  List<CourseGrade> get finished => [for (final c in courses) if (c.average != null) c];

  /// Units of the finished courses.
  int get finishedUnits => finished.fold(0, (sum, c) => sum + c.units);

  /// The GWA on SMCL's 1.00–5.00 scale, from each finished course's grade
  /// point (the registrar's way); null until a course is finished.
  double? gwa(AverageMethod method) => _mean(method, (c) => c.point!.point);

  /// The same average in percent, from the course averages as shown.
  double? percent(AverageMethod method) => _mean(method, (c) => c.average!.toDouble());

  double? _mean(AverageMethod method, double Function(CourseGrade) value) {
    final done = finished;
    if (done.isEmpty) return null;
    return switch (method) {
      AverageMethod.byUnits =>
        done.fold(0.0, (sum, c) => sum + value(c) * c.units) / finishedUnits,
      AverageMethod.simple => done.fold(0.0, (sum, c) => sum + value(c)) / done.length,
    };
  }
}
