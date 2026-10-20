import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/mock/mock_users.dart';
import 'package:michaelean_app/services/home_service.dart';

void main() {
  final service = MockHomeService(delay: Duration.zero);

  test('Nicolas sees his department and society posts, not others', () async {
    final feed = await service.loadStudentHome(mockStudent);
    final ids = feed.forYou.map((p) => p.id).toList();

    expect(ids, containsAll(['o1', 'o2', 'd1', 'e1']));
    expect(ids, isNot(contains('x1'))); // School of Nursing
    expect(ids, isNot(contains('x2'))); // Dance Company (not a member)
  });

  test('urgent posts come first in For You', () async {
    final feed = await service.loadStudentHome(mockStudent);
    expect(feed.forYou.first.urgent, isTrue);
    expect(feed.forYou.skip(1).every((p) => !p.urgent), isTrue);
  });

  test('no post appears in two sections', () async {
    final feed = await service.loadStudentHome(mockStudent);
    final all = [
      ...feed.announcements,
      if (feed.featuredNews != null) feed.featuredNews!,
      ...feed.moreNews,
      ...feed.forYou,
    ].map((p) => p.id).toList();
    expect(all.toSet().length, all.length);
  });
}
