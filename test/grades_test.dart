// Grades, step 1 (spec §7.6): course averages, the overall average by units
// (GWA) or simple, grades that aren't out yet, and the sample data.

import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/mock/mock_users.dart';
import 'package:michaelean_app/models/grades.dart';
import 'package:michaelean_app/services/campus_service.dart';

void main() {
  group('SMCL grading scale', () {
    test('every boundary lands on the right grade point', () {
      final cases = {
        100: '1.00', 99: '1.00', 98: '1.25', 96: '1.25', 95: '1.50', 93: '1.50',
        92: '1.75', 90: '1.75', 89: '2.00', 87: '2.00', 86: '2.25', 84: '2.25',
        83: '2.50', 81: '2.50', 80: '2.75', 78: '2.75', 77: '3.00', 75: '3.00',
        74: '4.00', 70: '4.00', 69: '5.00', 0: '5.00',
      };
      cases.forEach((percent, point) => expect(gradePointFor(percent).label, point,
          reason: '$percent%'));
    });

    test('4.00 is a conditional fail, 5.00 failed, and 3.00 passes', () {
      expect(gradePointFor(72).conditional, isTrue);
      expect(gradePointFor(72).failed, isFalse);
      expect(gradePointFor(65).failed, isTrue);
      expect(gradePointFor(75).conditional || gradePointFor(75).failed, isFalse);
      expect(gradePointFor(78).description, 'Low Pass');
    });
  });

  group('course average', () {
    test('is midterm and final averaged, rounded to a whole number', () {
      expect(const CourseGrade(code: 'A', units: 3, midterm: 88, finalGrade: 92).average, 90);
      expect(const CourseGrade(code: 'A', units: 3, midterm: 82, finalGrade: 99).average, 91); // 90.5
      expect(const CourseGrade(code: 'A', units: 3, midterm: 85, finalGrade: 90).average, 88); // 87.5
    });

    test('waits until both grades are out', () {
      expect(const CourseGrade(code: 'A', units: 3, midterm: 88).average, isNull);
      expect(const CourseGrade(code: 'A', units: 3).average, isNull);
    });

    test("converts to SMCL's grade point", () {
      expect(const CourseGrade(code: 'A', units: 3, midterm: 88, finalGrade: 92).point!.label, '1.75');
      expect(const CourseGrade(code: 'A', units: 3, midterm: 74, finalGrade: 75).point!.label, '3.00'); // 74.5 → 75
      expect(const CourseGrade(code: 'A', units: 3, midterm: 88).point, isNull); // not out yet
    });
  });

  group('overall average', () {
    // The example from the plan: 1458 ÷ 17 units.
    const sem = SemesterGrades(name: 'Sample', courses: [
      CourseGrade(code: 'CS 201', units: 3, midterm: 88, finalGrade: 92), // 90
      CourseGrade(code: 'CS 202', units: 3, midterm: 85, finalGrade: 90), // 88
      CourseGrade(code: 'MATH 201', units: 3, midterm: 78, finalGrade: 82), // 80
      CourseGrade(code: 'GE 103', units: 3, midterm: 90, finalGrade: 95), // 93
      CourseGrade(code: 'PE 102', units: 2, midterm: 95, finalGrade: 97), // 96
      CourseGrade(code: 'CS 203', units: 3, midterm: 72, finalGrade: 70), // 71
    ]);

    test('in percent, by units weighs each course by its units', () {
      expect(sem.finishedUnits, 17);
      expect(sem.percent(AverageMethod.byUnits), closeTo(1458 / 17, 1e-9));
      expect(sem.percent(AverageMethod.byUnits)!.toStringAsFixed(2), '85.76');
    });

    test('the GWA comes from the grade points: 38.50 ÷ 17 units = 2.26', () {
      // 1.75×3 + 2.00×3 + 2.75×3 + 1.50×3 + 1.25×2 + 4.00×3 = 38.50
      expect(sem.gwa(AverageMethod.byUnits), closeTo(38.5 / 17, 1e-9));
      expect(sem.gwa(AverageMethod.byUnits)!.toStringAsFixed(2), '2.26');
      expect(sem.gwa(AverageMethod.simple)!.toStringAsFixed(2), '2.21'); // 13.25 ÷ 6
    });

    test('simple counts every course the same', () {
      expect(sem.percent(AverageMethod.simple)!.toStringAsFixed(2), '86.33'); // 518 ÷ 6
    });

    test('counts only finished courses, and is empty before any', () {
      const partial = SemesterGrades(name: 'Now', courses: [
        CourseGrade(code: 'A', units: 3, midterm: 80),
        CourseGrade(code: 'B', units: 2, midterm: 93, finalGrade: 95), // 94
      ]);
      expect(partial.finished.map((c) => c.code), ['B']);
      expect(partial.finishedUnits, 2);
      expect(partial.percent(AverageMethod.byUnits), 94);
      const none = SemesterGrades(name: 'Start', courses: [
        CourseGrade(code: 'A', units: 3, midterm: 80),
      ]);
      expect(none.gwa(AverageMethod.byUnits), isNull);
      expect(none.percent(AverageMethod.simple), isNull);
    });
  });

  group('sample grades', () {
    final campus = MockCampusService(delay: Duration.zero, clock: () => DateTime(2026, 10, 25));

    test('a student gets this semester first, then two past semesters', () async {
      final sems = await campus.loadGrades(mockStudent);
      expect(sems.map((s) => s.name), [
        '1st Semester 2026–2027',
        '2nd Semester 2025–2026',
        '1st Semester 2025–2026',
      ]);
      // This semester's courses match the student's timetable; finals mostly not out.
      final now = sems.first;
      expect(now.courses.map((c) => c.code), ['CS 302', 'CS 305', 'CS 306', 'GE 104', 'PE 103']);
      expect(now.finished.length, 1);
      // One conditional fail (4.00) and one failed course (5.00) in the past.
      expect(sems.last.courses.where((c) => c.point?.conditional ?? false).map((c) => c.code),
          ['CS 203']);
      expect(sems[1].courses.where((c) => c.point?.failed ?? false).map((c) => c.code),
          ['MATH 202']);
    });

    test('a teacher gets no grades', () async {
      expect(await campus.loadGrades(mockTeacher), isEmpty);
    });

    test('the school year starts in June', () async {
      final march = MockCampusService(delay: Duration.zero, clock: () => DateTime(2027, 3, 1));
      expect((await march.loadGrades(mockStudent)).first.name, '1st Semester 2026–2027');
    });
  });
}
