import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/mock/mock_home.dart';
import 'package:michaelean_app/mock/mock_users.dart';
import 'package:michaelean_app/services/home_service.dart';

void main() {
  final service = MockHomeService(delay: Duration.zero);

  test('Nicolas sees his department and society posts, not others', () async {
    final feed = await service.loadHome(mockStudent);
    final ids = feed.forYou.map((p) => p.id).toList();

    expect(ids, containsAll(['o1', 'o2', 'd1', 'e1']));
    expect(ids, isNot(contains('x1'))); // School of Nursing
    expect(ids, isNot(contains('x2'))); // Dance Company (not a member)
  });

  test('urgent posts come first in For You', () async {
    final feed = await service.loadHome(mockStudent);
    expect(feed.forYou.first.urgent, isTrue);
    expect(feed.forYou.skip(1).every((p) => !p.urgent), isTrue);
  });

  group('teacher', () {
    // 10:00 on a fixed day: the 7:30 class is over, 10:30 is next.
    final morning = DateTime(2026, 10, 20, 10, 0);
    final teacherService = MockHomeService(delay: Duration.zero, clock: () => morning);

    test('gets teacher sections, not student ones', () async {
      final feed = await teacherService.loadHome(mockTeacher);
      expect(feed.attendance, isNull);
      expect(feed.today!.classesToday, 3);
      expect(feed.changes.map((p) => p.id), ['c1']);
      expect(feed.forYou.map((p) => p.id), isNot(contains('o1'))); // CSS-only post
    });

    test('attendance task exists only for an unfinalized session', () async {
      final feed = await teacherService.loadHome(mockTeacher);
      final finalize = feed.tasks.where((t) => t.title == 'Finalize attendance');
      expect(finalize.length, feed.today!.sessionsToFinalize);
      expect(finalize.length, 1); // only CS 301; the other classes create no task
    });

    test('next class: later today, then tomorrow, then none', () {
      final classes = mockTeacherClasses(morning);
      expect(nextClass(classes, morning)!.id, 'k2');
      expect(nextClass(classes, DateTime(2026, 10, 20, 20))!.id, 'k4'); // evening
      expect(nextClass(classes, DateTime(2026, 10, 22)), isNull);
      expect(nextClass(const [], morning), isNull);
    });

    test('class in progress counts as next', () {
      final classes = mockTeacherClasses(morning);
      expect(nextClass(classes, DateTime(2026, 10, 20, 11))!.id, 'k2');
    });
  });

  test('no post appears in two sections', () async {
    final feed = await service.loadHome(mockStudent);
    final all = [
      ...feed.announcements,
      if (feed.featuredNews != null) feed.featuredNews!,
      ...feed.moreNews,
      ...feed.forYou,
    ].map((p) => p.id).toList();
    expect(all.toSet().length, all.length);
  });
}
