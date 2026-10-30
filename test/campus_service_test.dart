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

  test('clearance: active for the student; office only with permission', () async {
    final c = await service.loadClearance(mockStudent);
    expect(c!.cleared, 3);
    expect(c.total, 7); // Not applicable doesn't count
    expect(c.needsCorrection, 1);
    expect(await service.loadClearance(mockTeacher), isNull);
    expect((await service.loadClearanceOffice(mockTeacher))!.pendingCount, 3);
    expect(await service.loadClearanceOffice(mockStudent), isNull); // no permission
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

  group('events (spec §7.3, §9.2)', () {
    MockCampusService fresh() => MockCampusService(delay: Duration.zero, clock: () => morning);

    test('registration: once only; never for full, closed, or ineligible events', () async {
      final s = fresh();
      await s.register(mockStudent, 'ev1');
      expect((await s.loadEvent(mockStudent, 'ev1'))!.registered, isTrue);
      expect(() => s.register(mockStudent, 'ev1'), throwsStateError); // duplicate
      expect(() => s.register(mockStudent, 'ev4'), throwsStateError); // deadline passed
      expect(() => s.register(mockStudent, 'ev5'), throwsStateError); // full
      expect(() => s.register(mockStudent, 'ev6'), throwsStateError); // not a member
      expect(await s.loadEvent(mockStudent, 'ev6'), isNull);
      expect(await s.loadEvent(mockStudent, 'ev7'), isNull); // draft
    });

    test('My events: upcoming registrations, then past ones', () async {
      final mine = await fresh().loadEvents(mockStudent, EventList.mine);
      // Upcoming, then past newest first; past events with a record count too.
      expect(mine.map((d) => d.event.id),
          ['ev3', 'ev8', 'past-git', 'past-startup', 'past-iris']);
      expect(mine.firstWhere((d) => d.event.id == 'ev8').record, isNull); // registered only
    });

    test('drafts, publishing, and editing the same event', () async {
      final s = fresh();
      final start = DateTime(2026, 11, 3, 13);
      final draft = await s.saveEvent(mockTeacher,
          publish: false,
          title: 'Hackathon',
          start: start,
          end: start.add(const Duration(hours: 3)),
          venue: 'Lab 1');
      expect(draft.status, EventStatus.draft);
      expect(await s.loadEvent(mockStudent, draft.id), isNull); // students can't see drafts

      final published = await s.saveEvent(mockTeacher,
          eventId: draft.id,
          publish: true,
          title: 'Hackathon',
          start: start,
          end: start.add(const Duration(hours: 3)),
          venue: 'Lab 2');
      expect(published.id, draft.id); // same event, not a copy
      expect(published.status, EventStatus.published);
      expect(published.updateNote, isNull); // it wasn't published before

      final moved = await s.saveEvent(mockTeacher,
          eventId: draft.id,
          publish: false, // a published event stays published
          title: 'Hackathon',
          start: start.add(const Duration(days: 1)),
          end: start.add(const Duration(days: 1, hours: 3)),
          venue: 'Lab 2');
      expect(moved.status, EventStatus.published);
      expect(moved.updateNote, isNotNull);

      final managed = await s.loadEvents(mockTeacher, EventList.managed);
      expect(managed.where((d) => d.event.title == 'Hackathon'), hasLength(1));
    });

    test('managers only; validation is checked by the service too', () async {
      final s = fresh();
      final start = DateTime(2026, 11, 3, 13);
      expect(
          () => s.saveEvent(mockTeacher,
              eventId: 'ev1', // a CSS event the teacher doesn't manage
              publish: true,
              title: 'X',
              start: start,
              end: start.add(const Duration(hours: 1)),
              venue: 'Y'),
          throwsStateError);
      expect(
          () => s.saveEvent(mockTeacher,
              publish: true, title: 'X', start: start, end: start, venue: 'Y'),
          throwsArgumentError); // ends when it starts
      expect(
          () => s.saveEvent(mockTeacher,
              publish: true,
              title: 'X',
              start: DateTime(2026, 10, 19, 13),
              end: DateTime(2026, 10, 19, 14),
              venue: 'Y'),
          throwsArgumentError); // published in the past
      expect(await s.loadRegistrations(mockStudent, 'ev2'), isNull);
    });

    test('inviting a section registers its students automatically', () async {
      final s = fresh();
      expect(await s.invite(mockTeacher, 'ev2', sections: ['BSCS 3A']), 7); // 5 already registered
      final regs = (await s.loadRegistrations(mockTeacher, 'ev2'))!;
      expect(regs, hasLength(12));
      expect(regs.where((r) => r.invited), hasLength(7));
      final mine = await s.loadEvent(mockStudent, 'ev2');
      expect((mine!.registered, mine.invited), (true, true));
      expect(() => s.invite(mockTeacher, 'ev7', sections: ['BSCS 3A']), throwsStateError); // draft
      expect(() => s.invite(mockTeacher, 'ev2', sections: ['BSCS 1Z']), throwsStateError);
    });

    test('cancelling an event hides it from Discover but keeps registrations', () async {
      final s = fresh();
      await s.invite(mockTeacher, 'ev2', sections: ['BSCS 3A']);
      await s.cancelEvent(mockTeacher, 'ev2');
      final discover = await s.loadEvents(mockStudent, EventList.discover);
      expect(discover.map((d) => d.event.id), isNot(contains('ev2')));
      final mine = await s.loadEvents(mockStudent, EventList.mine);
      expect(mine.firstWhere((d) => d.event.id == 'ev2').event.status, EventStatus.cancelled);
      expect(() => s.cancelEvent(mockStudent, 'ev3'), throwsStateError);
    });
  });

  group('organizations (spec §7.4)', () {
    MockCampusService fresh() => MockCampusService(delay: Duration.zero, clock: () => morning);

    test('directory: own department society, clubs, memberships', () async {
      final d = await fresh().loadOrganizationDirectory(mockStudent);
      expect(d.society.map((o) => o.name), ['Computer Science Society']);
      // Another department's society is never a school-wide club.
      expect(d.clubs.map((o) => o.name), isNot(contains('Nursing Students Association')));
      expect(d.clubs.map((o) => o.name), contains('Dance Company'));
      expect(d.mine.map((o) => o.name), ['Computer Science Society', 'SMCL Chorale']);
    });

    test('page: members see members-only events and posts; others see a note', () async {
      final s = fresh();
      final css = (await s.loadOrganization(mockStudent, 'org1'))!;
      expect(css.isMember, isTrue);
      expect(css.events.map((d) => d.event.id), ['ev1', 'ev4']);
      expect(css.news, isNotEmpty);
      expect(css.membersOnlyHidden, 0);

      final dance = (await s.loadOrganization(mockStudent, 'org3'))!;
      expect(dance.isMember, isFalse);
      expect(dance.events, isEmpty); // its showcase is for members only
      expect(dance.membersOnlyHidden, greaterThan(0));

      expect(await s.loadOrganization(mockStudent, 'org5'), isNull); // other department
    });

    test('a join request never makes the student a member', () async {
      final s = fresh();
      await s.requestToJoin(mockStudent, 'org3');
      final dance = (await s.loadOrganization(mockStudent, 'org3'))!;
      expect((dance.requested, dance.isMember), (true, false));
      expect(() => s.requestToJoin(mockStudent, 'org3'), throwsStateError); // twice
      expect(() => s.requestToJoin(mockStudent, 'org1'), throwsStateError); // already a member
    });
  });

  group('clearance (spec §7.5, §9.3)', () {
    MockCampusService fresh() => MockCampusService(delay: Duration.zero, clock: () => morning);
    Future<ClearanceStatus> statusOf(MockCampusService s, String id) async =>
        (await s.loadClearanceView(mockStudent)).active!.items.firstWhere((i) => i.id == id).status;

    test('submitting only sends for review; it never clears', () async {
      final s = fresh();
      await s.markSubmitted(mockStudent, 'lib'); // needs correction → resubmitted
      expect(await statusOf(s, 'lib'), ClearanceStatus.inReview);
      expect(() => s.markSubmitted(mockStudent, 'acc'), throwsStateError); // already cleared
      expect(() => s.markSubmitted(mockStudent, 'pub'), throwsStateError); // not applicable
    });

    test('a QR scan only finds the student', () async {
      final s = fresh();
      expect(await s.findStudentByQr(mockTeacher, mockStudent.qrToken), mockStudent.id);
      expect(await s.findStudentByQr(mockTeacher, 'MOCK-UNKNOWN'), isNull);
      expect(await statusOf(s, 'dcs-lab'), ClearanceStatus.inReview); // unchanged
      expect(() => s.findStudentByQr(mockStudent, mockStudent.qrToken), throwsStateError);
    });

    test('staff record outcomes only for their office, with a reason when not cleared',
        () async {
      final s = fresh();
      final c = (await s.loadClearanceCase(mockTeacher, mockStudent.id))!;
      expect(c.items.map((i) => i.id), ['dcs-lab', 'dcs-adviser']); // this office only
      expect(
          () => s.recordOutcome(mockTeacher, mockStudent.id, 'lib', ClearanceStatus.cleared),
          throwsStateError); // the Library's requirement
      expect(
          () => s.recordOutcome(
              mockTeacher, mockStudent.id, 'dcs-lab', ClearanceStatus.needsCorrection),
          throwsArgumentError); // no reason
      expect(
          () => s.recordOutcome(mockStudent, mockStudent.id, 'dcs-lab', ClearanceStatus.cleared),
          throwsStateError); // no permission

      await s.recordOutcome(mockTeacher, mockStudent.id, 'dcs-lab', ClearanceStatus.cleared);
      expect(await statusOf(s, 'dcs-lab'), ClearanceStatus.cleared);
      expect((await s.loadClearance(mockStudent))!.cleared, 4);
      expect((await s.loadClearanceDesk(mockTeacher))!.pending, hasLength(2));
    });
  });

  group('event history and check-in', () {
    MockCampusService fresh() => MockCampusService(delay: Duration.zero, clock: () => morning);

    test('each history record opens its event, with the record', () async {
      final s = fresh();
      final history = await s.loadEventHistory(mockStudent);
      expect(history.map((r) => r.eventId), ['past-git', 'past-startup', 'past-iris']);
      final d = (await s.loadEvent(mockStudent, 'past-iris'))!;
      expect(d.record!.status.label, 'Attended');
      // Not a CSS member, but the record still opens the event.
      final t = (await s.loadEvent(mockTeacher, 'past-git'))!;
      expect(t.record!.role.label, 'Organizer');
    });

    test('check-in marks registered students once, then finalizing adds records', () async {
      final s = fresh();
      await s.invite(mockTeacher, 'ev2', sections: ['BSCS 3A']); // registers the mock student
      expect((await s.recordEventScan(mockTeacher, 'ev2', mockStudent.qrToken)).outcome,
          ScanOutcome.notOpenYet); // three days away
      Future<ScanOutcome> scan(String token) async =>
          (await s.recordEventScan(mockTeacher, 'ev2', token, ignoreClock: true)).outcome;
      expect(await scan('MOCK-UNKNOWN'), ScanOutcome.notEnrolled);
      expect(await scan('MOCK-BSCS3B1'), ScanOutcome.notEnrolled); // not registered
      expect(await scan(mockStudent.qrToken), ScanOutcome.present);
      expect(await scan(mockStudent.qrToken), ScanOutcome.duplicate);
      expect(() => s.recordEventScan(mockStudent, 'ev2', mockStudent.qrToken), throwsStateError);

      expect(await s.finalizeEventAttendance(mockTeacher, 'ev2'), 1);
      final history = await s.loadEventHistory(mockStudent);
      expect(history.first.eventId, 'ev2');
      expect(history.first.status.label, 'Attended');
      expect(await scan(mockStudent.qrToken), ScanOutcome.closed);
      expect(() => s.finalizeEventAttendance(mockTeacher, 'ev2'), throwsStateError);
      final d = (await s.loadEvent(mockTeacher, 'ev2'))!;
      expect((d.attendanceFinalized, d.attendedCount), (true, 1));
    });
  });
}
