import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/mock/mock_users.dart';
import 'package:michaelean_app/models/attendance.dart';
import 'package:michaelean_app/models/campus.dart';
import 'package:michaelean_app/services/campus_service.dart';

void main() {
  // 10:00 on a fixed day.
  final morning = DateTime(2026, 10, 20, 10, 0);
  final service = MockCampusService(delay: Duration.zero, clock: () => morning);

  test('students see only published events they are eligible for, soonest first', () async {
    final events = await service.loadUpcomingEvents(mockStudent);
    final ids = events.map((e) => e.id).toList();
    expect(ids, ['ev1', 'ev2', 'ev3', 'ev4', 'ev5']);
    expect(ids, isNot(contains('ev6'))); // Dance Company: not a member
    expect(ids, isNot(contains('ev7'))); // draft
  });

  test('managed events: only the teacher\'s own, drafts included', () async {
    final events = await service.loadManagedEvents(mockTeacher);
    expect(events.map((e) => e.id), ['ev2', 'ev7']);
    expect(events.last.status, EventStatus.draft);
    expect(await service.loadManagedEvents(mockStudent), isEmpty); // no permission
  });

  test('organizations come from confirmed membership tags', () async {
    final orgs = await service.loadMyOrganizations(mockStudent);
    expect(orgs.map((o) => o.name), ['Computer Science Society', 'SMCL Chorale']);
    expect(await service.loadMyOrganizations(mockTeacher), isEmpty);
  });

  test('clearance: active for the student; no office without permission', () async {
    final c = await service.loadClearance(mockStudent);
    expect(c!.cleared, 3);
    expect(c.total, 6);
    expect(await service.loadClearance(mockTeacher), isNull);
    expect(await service.loadClearanceOffice(mockTeacher), isNull);
  });

  test('classes: today (also ended ones) and later, in time order', () async {
    final classes = await service.loadClasses(mockStudent);
    expect(classes.take(3).map((c) => c.subject), [
      'CS 305 · Software Engineering', // 7:30, already over at 10:00
      'CS 302 · Algorithms',
      'GE 104 · Ethics',
    ]);
    expect(classes.first.teacher, 'Ana Reyes');
  });

  group('attendance rules (spec §7.2)', () {
    // Tuesday CS 302 runs 10:30–12:00. The clock is moved per test.
    late DateTime now;
    late MockCampusService s;
    const cs302 = 'cs302-3a@2026-10-20';
    setUp(() {
      now = DateTime(2026, 10, 20, 10, 40); // during class
      s = MockCampusService(delay: Duration.zero, clock: () => now);
    });

    test('enrolled student: Present once; a second scan counts once', () async {
      final first = await s.recordScan(mockTeacher, cs302, mockStudent.qrToken);
      expect(first.outcome, ScanOutcome.present);
      expect(first.student!.name, 'Nicolas Santos');
      final again = await s.recordScan(mockTeacher, cs302, mockStudent.qrToken);
      expect(again.outcome, ScanOutcome.duplicate);
      final att = await s.loadSessionAttendance(mockTeacher, cs302);
      expect(att!.presentCount, 1);
    });

    test('unknown and other-section codes are not marked', () async {
      expect((await s.recordScan(mockTeacher, cs302, 'MOCK-UNKNOWN')).outcome,
          ScanOutcome.notEnrolled);
      expect((await s.recordScan(mockTeacher, cs302, 'MOCK-BSCS2A1')).outcome,
          ScanOutcome.notEnrolled); // a BSCS 2A student, not on this roster
      expect((await s.loadSessionAttendance(mockTeacher, cs302))!.presentCount, 0);
    });

    test('scans before the start or after the end are rejected', () async {
      now = DateTime(2026, 10, 20, 10, 0);
      expect((await s.recordScan(mockTeacher, cs302, mockStudent.qrToken)).outcome,
          ScanOutcome.notOpenYet);
      now = DateTime(2026, 10, 20, 12, 0);
      expect((await s.recordScan(mockTeacher, cs302, mockStudent.qrToken)).outcome,
          ScanOutcome.closed);
      // The preview tool skips only the clock check, nothing else.
      expect(
          (await s.recordScan(mockTeacher, cs302, 'MOCK-UNKNOWN', ignoreClock: true)).outcome,
          ScanOutcome.notEnrolled);
    });

    test('finalizing closes the session; only finalized sessions count', () async {
      await s.recordScan(mockTeacher, cs302, mockStudent.qrToken);
      now = DateTime(2026, 10, 20, 12, 30);
      final before = await s.loadMyAttendance(mockStudent);
      expect(before.where((r) => r.session.id == cs302), isEmpty); // not finalized yet

      await s.finalizeSession(mockTeacher, cs302);
      final after = await s.loadMyAttendance(mockStudent);
      expect(after.firstWhere((r) => r.session.id == cs302).mark, AttendanceMark.present);
      expect((await s.recordScan(mockTeacher, cs302, 'MOCK-BSCS3A1', ignoreClock: true)).outcome,
          ScanOutcome.closed); // no scans after finalization
    });

    test("teachers manage only their assigned classes; students can't", () async {
      const cs305 = 'cs305-3a@2026-10-20'; // Ana Reyes's class
      expect(await s.loadSessionAttendance(mockTeacher, cs305), isNull);
      expect(() => s.recordScan(mockTeacher, cs305, mockStudent.qrToken), throwsStateError);
      expect(await s.loadSessionAttendance(mockStudent, cs302), isNull);
      expect(await s.loadClassDetail(mockTeacher, 'cs305-3a'), isNull);
    });

    test('class page: roster and recent sessions, newest first', () async {
      final d = await s.loadClassDetail(mockTeacher, 'cs302-3a');
      expect(d!.roster.length, 12);
      expect(d.roster.first.name, 'Nicolas Santos');
      expect(d.current!.id, cs302); // today's session
      final dates = d.recent.map((r) => r.session.start).toList();
      expect(dates, [...dates]..sort((a, b) => b.compareTo(a)));
    });

    test('changing one session: validated, and only that session moves', () async {
      expect(
          () => s.updateSession(mockTeacher, cs302,
              start: DateTime(2026, 10, 20, 12), end: DateTime(2026, 10, 20, 11), room: 'X'),
          throwsArgumentError);
      expect(
          () => s.updateSession(mockTeacher, cs302,
              start: DateTime(2026, 10, 20, 13), end: DateTime(2026, 10, 20, 14), room: ' '),
          throwsArgumentError);
      await s.updateSession(mockTeacher, cs302,
          start: DateTime(2026, 10, 20, 13), end: DateTime(2026, 10, 20, 14), room: 'Room 405');
      final classes = await s.loadClasses(mockTeacher);
      final moved = classes.firstWhere((c) => c.id == cs302);
      expect((moved.start.hour, moved.room), (13, 'Room 405'));
      final thursday = classes.firstWhere((c) => c.id == 'cs302-3a@2026-10-22');
      expect((thursday.start.hour, thursday.room), (10, 'Segunda Limaco Hall · 301'));
    });
  });
}
