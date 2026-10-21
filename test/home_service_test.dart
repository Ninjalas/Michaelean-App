import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/mock/mock_users.dart';
import 'package:michaelean_app/models/attendance.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';

void main() {
  final service = MockHomeService(delay: Duration.zero);

  test('Nicolas sees his department and society posts, not others', () async {
    final feed = await service.loadHome(mockStudent);
    final ids = feed.campusFeed.map((p) => p.id).toList();

    expect(ids, containsAll(['o1', 'o2', 'd1', 'e1']));
    expect(ids, isNot(contains('x1'))); // School of Nursing
    expect(ids, isNot(contains('x2'))); // Dance Company (not a member)
  });

  test('urgent posts are pinned first in the campus feed', () async {
    final feed = await service.loadHome(mockStudent);
    expect(feed.campusFeed.first.urgent, isTrue);
    expect(feed.campusFeed.skip(1).every((p) => !p.urgent), isTrue);
  });

  test('student Up next is their own next class, with its teacher', () async {
    // 10:00: the 7:30 class is over, CS 302 at 10:30 is next.
    final atTen = MockHomeService(
        delay: Duration.zero, clock: () => DateTime(2026, 10, 20, 10, 0));
    final feed = await atTen.loadHome(mockStudent);
    expect(feed.nextClass!.subject, 'CS 302 · Algorithms');
    expect(feed.nextClass!.teacher, 'Mark Villanueva');
    expect(feed.todayClasses, isEmpty); // Today's classes is a teacher section
  });

  test('class attendance % is counted from finalized records only', () async {
    DateTime clock() => DateTime(2026, 10, 20, 10, 0);
    final campus = MockCampusService(delay: Duration.zero, clock: clock);
    final home = MockHomeService(delay: Duration.zero, clock: clock, campus: campus);
    final records = await campus.loadMyAttendance(mockStudent);
    final present = records.where((r) => r.mark == AttendanceMark.present).length;
    final feed = await home.loadHome(mockStudent);
    expect(records, isNotEmpty);
    expect(records.every((r) => r.session.finalized), isTrue);
    expect(feed.attendance!.classPercent, (present * 100 / records.length).round());
  });

  group('teacher', () {
    // Tuesday 10:00: the 7:30 CS 301 is over (scanned, not finalized), 10:30 is next.
    final morning = DateTime(2026, 10, 20, 10, 0);
    final teacherService = MockHomeService(delay: Duration.zero, clock: () => morning);

    test('gets teacher sections, not student ones', () async {
      final feed = await teacherService.loadHome(mockTeacher);
      expect(feed.attendance, isNull);
      expect(feed.today!.classesToday, 3);
      expect(feed.changes.map((p) => p.id), ['c1']);
      expect(feed.campusFeed.map((p) => p.id), isNot(contains('o1'))); // CSS-only post
    });

    test("today's classes: only today, in time order", () async {
      final feed = await teacherService.loadHome(mockTeacher);
      expect(feed.todayClasses.map((c) => c.subject), [
        'CS 301 · Data Structures',
        'CS 302 · Algorithms',
        'CS 310 · Web Development',
      ]); // not Wednesday's
    });

    test('attendance task exists only for an unfinalized session', () async {
      final feed = await teacherService.loadHome(mockTeacher);
      final finalize = feed.tasks.where((t) => t.title == 'Finalize attendance');
      expect(finalize.length, feed.today!.sessionsToFinalize);
      expect(finalize.length, 1); // only CS 301; the other classes create no task
    });

    test('next class: later today, then the next day, then none', () async {
      final classes = await MockCampusService(delay: Duration.zero, clock: () => morning)
          .loadClasses(mockTeacher);
      expect(nextClass(classes, morning)!.subject, 'CS 302 · Algorithms');
      // Tuesday evening: Wednesday's CS 310 comes next.
      final evening = nextClass(classes, DateTime(2026, 10, 20, 20))!;
      expect((evening.subject, evening.start.weekday), ('CS 310 · Web Development', DateTime.wednesday));
      expect(nextClass(classes, DateTime(2026, 12, 1)), isNull); // beyond the loaded week
      expect(nextClass(const [], morning), isNull);
    });

    test('class in progress counts as next', () async {
      final classes = await MockCampusService(delay: Duration.zero, clock: () => morning)
          .loadClasses(mockTeacher);
      expect(nextClass(classes, DateTime(2026, 10, 20, 11))!.subject, 'CS 302 · Algorithms');
    });

    test('finalizing in the class screens removes the Home task', () async {
      final campus = MockCampusService(delay: Duration.zero, clock: () => morning);
      final home = MockHomeService(delay: Duration.zero, clock: () => morning, campus: campus);
      final before = await home.loadHome(mockTeacher);
      final task = before.tasks.firstWhere((t) => t.title == 'Finalize attendance');
      expect(task.route, startsWith('/attendance/cs301-2a@'));

      await campus.finalizeSession(mockTeacher, task.route!.split('/')[2]);
      final after = await home.loadHome(mockTeacher);
      expect(after.tasks.where((t) => t.title == 'Finalize attendance'), isEmpty);
      expect(after.today!.sessionsToFinalize, 0);
    });
  });

  test('no post appears in two sections', () async {
    final feed = await service.loadHome(mockStudent);
    final all = [
      ...feed.announcements,
      if (feed.featuredNews != null) feed.featuredNews!,
      ...feed.moreNews,
      ...feed.campusFeed,
    ].map((p) => p.id).toList();
    expect(all.toSet().length, all.length);
  });
}
