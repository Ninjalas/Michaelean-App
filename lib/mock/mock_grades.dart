// MOCK DATA — sample grades for the preview student (spec §7.6). Invented
// numbers, not official school records. This semester's courses match the
// student's timetable (BSCS 3A); past semesters are complete, with one
// conditional fail (4.00) and one failed course (5.00) so both styles show.

import '../models/grades.dart';

/// The preview student's semesters, newest first. Named from [now]'s school
/// year (June to May), e.g. "1st Semester 2026–2027".
List<SemesterGrades> mockGrades(DateTime now) {
  final y = now.month >= 6 ? now.year : now.year - 1; // school year starts in June
  return [
    // This semester: midterms are out; finals only for GE 104 so far.
    SemesterGrades(name: '1st Semester $y–${y + 1}', courses: const [
      CourseGrade(code: 'CS 302', units: 3, midterm: 88),
      CourseGrade(code: 'CS 305', units: 3, midterm: 91),
      CourseGrade(code: 'CS 306', units: 3, midterm: 84),
      CourseGrade(code: 'GE 104', units: 3, midterm: 93, finalGrade: 95),
      CourseGrade(code: 'PE 103', units: 2, midterm: 96),
    ]),
    SemesterGrades(name: '2nd Semester ${y - 1}–$y', courses: const [
      CourseGrade(code: 'CS 204', units: 3, midterm: 87, finalGrade: 90),
      CourseGrade(code: 'CS 205', units: 3, midterm: 92, finalGrade: 94),
      CourseGrade(code: 'MATH 202', units: 3, midterm: 66, finalGrade: 68), // 67: failed (5.00)
      CourseGrade(code: 'GE 105', units: 3, midterm: 89, finalGrade: 91),
      CourseGrade(code: 'PE 104', units: 2, midterm: 98, finalGrade: 99),
    ]),
    SemesterGrades(name: '1st Semester ${y - 1}–$y', courses: const [
      CourseGrade(code: 'CS 201', units: 3, midterm: 88, finalGrade: 92),
      CourseGrade(code: 'CS 202', units: 3, midterm: 85, finalGrade: 90),
      CourseGrade(code: 'MATH 201', units: 3, midterm: 78, finalGrade: 82),
      CourseGrade(code: 'GE 103', units: 3, midterm: 90, finalGrade: 95),
      CourseGrade(code: 'PE 102', units: 2, midterm: 95, finalGrade: 97),
      CourseGrade(code: 'CS 203', units: 3, midterm: 72, finalGrade: 70), // 71: conditional fail (4.00)
    ]),
  ];
}
