// MOCK DATA — sample timetable, rosters, and attendance for the frontend
// prototype. Students, teachers (other than the two preview accounts),
// rooms, and times are invented. No real student records.

import '../models/attendance.dart';
import 'mock_users.dart';

int _at(int hour, int minute) => hour * 60 + minute;

const _mon = DateTime.monday, _tue = DateTime.tuesday, _wed = DateTime.wednesday;
const _thu = DateTime.thursday, _fri = DateTime.friday, _sat = DateTime.saturday;

final mockTimetable = <ClassInfo>[
  // Mark Villanueva (the mock teacher).
  ClassInfo(
    id: 'cs301-2a',
    subject: 'CS 301 · Data Structures',
    section: 'BSCS 2A',
    room: 'Pura Limaco Hall I · 204',
    teacherId: mockTeacher.id,
    teacherName: 'Mark Villanueva',
    weekdays: const [_tue, _thu],
    startMinute: _at(7, 30),
    endMinute: _at(9, 0),
  ),
  ClassInfo(
    id: 'cs302-3a',
    subject: 'CS 302 · Algorithms',
    section: 'BSCS 3A',
    room: 'Segunda Limaco Hall · 301',
    teacherId: mockTeacher.id,
    teacherName: 'Mark Villanueva',
    weekdays: const [_tue, _thu],
    startMinute: _at(10, 30),
    endMinute: _at(12, 0),
  ),
  ClassInfo(
    id: 'cs310-3b',
    subject: 'CS 310 · Web Development',
    section: 'BSCS 3B',
    room: 'Saint Theodore Hall · Lab 2',
    teacherId: mockTeacher.id,
    teacherName: 'Mark Villanueva',
    weekdays: const [_mon, _tue, _wed, _fri],
    startMinute: _at(13, 0),
    endMinute: _at(14, 30),
  ),
  // Other BSCS 3A classes (invented teachers).
  ClassInfo(
    id: 'cs305-3a',
    subject: 'CS 305 · Software Engineering',
    section: 'BSCS 3A',
    room: 'Saint Theodore Hall · Lab 1',
    teacherId: 'mock-teacher-2',
    teacherName: 'Ana Reyes',
    weekdays: const [_mon, _tue, _wed],
    startMinute: _at(7, 30),
    endMinute: _at(9, 0),
  ),
  ClassInfo(
    id: 'ge104-3a',
    subject: 'GE 104 · Ethics',
    section: 'BSCS 3A',
    room: 'Pura Limaco Hall I · 110',
    teacherId: 'mock-teacher-3',
    teacherName: 'Jose Cruz',
    weekdays: const [_tue, _fri],
    startMinute: _at(13, 0),
    endMinute: _at(14, 30),
  ),
  ClassInfo(
    id: 'cs306-3a',
    subject: 'CS 306 · Computer Networks',
    section: 'BSCS 3A',
    room: 'Saint Theodore Hall · Lab 3',
    teacherId: 'mock-teacher-4',
    teacherName: 'Paolo Garcia',
    weekdays: const [_mon, _thu],
    startMinute: _at(15, 0),
    endMinute: _at(16, 30),
  ),
  ClassInfo(
    id: 'pe103-3a',
    subject: 'PE 103 · Team Sports',
    section: 'BSCS 3A',
    room: 'Main Grounds',
    teacherId: 'mock-teacher-5',
    teacherName: 'Liza Ramos',
    weekdays: const [_sat],
    startMinute: _at(8, 0),
    endMinute: _at(10, 0),
  ),
];

/// Which section each mock student account belongs to.
final mockStudentSection = {mockStudent.id: 'BSCS 3A'};

RosterStudent _student(String section, int n, String name) {
  final code = '${section.replaceAll(' ', '')}$n';
  return RosterStudent(
    id: 'stu-$code',
    name: name,
    maskedId: '2023-****-${(n * 7 + 11).toString().padLeft(2, '0')}',
    qrToken: 'MOCK-${code.toUpperCase()}',
  );
}

List<RosterStudent> _roster(String section, List<String> names) =>
    [for (var i = 0; i < names.length; i++) _student(section, i + 1, names[i])];

final mockRosters = <String, List<RosterStudent>>{
  'BSCS 3A': [
    RosterStudent(
      id: mockStudent.id,
      name: mockStudent.fullName,
      maskedId: mockStudent.maskedId,
      qrToken: mockStudent.qrToken,
      photoAsset: mockStudent.photoAsset,
    ),
    ..._roster('BSCS 3A', [
      'Andrea Bautista', 'Carlo Mendoza', 'Bea Villareal', 'Diego Ramos',
      'Erika Lim', 'Francis Tan', 'Gabrielle Ocampo', 'Hans Navarro',
      'Isabel Cruz', 'Joshua Dizon', 'Kyla Aquino',
    ]),
  ],
  'BSCS 2A': _roster('BSCS 2A', [
    'Aira Domingo', 'Ben Salazar', 'Cielo Reyes', 'Dan Castillo', 'Ella Morales',
    'Gino Santiago', 'Hannah Uy', 'Ivan Lopez', 'Jade Pascual', 'Ken Flores',
    'Lara Valdez', 'Miko Rivera',
  ]),
  'BSCS 3B': _roster('BSCS 3B', [
    'Alyssa Go', 'Bryan Cortez', 'Celine Yap', 'Daryl Manalo', 'Elaine Sy',
    'Fritz Javier', 'Grace Soriano', 'Harold Chua', 'Ina Torres', 'Jomar Bello',
    'Kat Robles', 'Leo Marquez',
  ]),
};

/// Seeded absences for past, already-finalized sessions: about 1 in 9,
/// picked by a simple stable sum (same result on every platform).
bool mockWasAbsent(String sessionId, String studentId) =>
    (sessionId + studentId).codeUnits.fold(0, (a, b) => a + b) % 9 == 0;

/// The one session of today that was scanned but not finalized yet, so the
/// teacher has a real "Finalize attendance" task: today's CS 301, with the
/// first 10 students scanned.
const mockSeededOpenClassId = 'cs301-2a';
const mockSeededScanCount = 10;

/// MOCK semester: about 10 weeks before and 8 weeks after today, Monday to
/// Saturday, so the prototype is always "mid-semester" whenever it runs.
/// Real semester dates will come from the school calendar.
({String name, DateTime start, DateTime end}) mockSemester(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final monday = today.subtract(Duration(days: today.weekday - 1));
  return (
    name: '1st Semester',
    start: monday.subtract(const Duration(days: 7 * 10)),
    end: monday.add(const Duration(days: 7 * 8 + 5)), // a Saturday
  );
}
