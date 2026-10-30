// The bell builds its notices from posts and events (decided 2026-10-30):
// announcements, department news, and club posts (members only), plus new
// events the user can join, all from the last 7 days. School News isn't in it.

import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/mock/mock_users.dart';
import 'package:michaelean_app/models/feed.dart';
import 'package:michaelean_app/models/user_profile.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';

void main() {
  final now = DateTime(2026, 10, 30, 12); // a Friday
  late MockCampusService campus;
  late MockHomeService home;

  setUp(() {
    campus = MockCampusService(delay: Duration.zero, clock: () => now);
    home = MockHomeService(delay: Duration.zero, clock: () => now, campus: campus);
  });

  Future<List<String>> titles(UserProfile user) async =>
      [for (final n in await home.loadNotifications(user)) n.title];

  test('student: new announcements, club posts, and events; nothing old or not theirs', () async {
    final bell = await titles(mockStudent);
    expect(bell, containsAll([
      'New announcement: Midterm examination schedule posted',
      "Urgent: Computer Science Society: Venue change for Friday's general meeting",
      'Computer Science Society: Recap: hands-on Git and collaboration seminar',
      'New event: CSS General Assembly · Sun, 1 Nov',
      'New event: Blood Donation Drive · Wed, 11 Nov',
    ]));
    String? find(String part) => bell.where((t) => t.contains(part)).firstOrNull;
    expect(find('Intramurals'), isNull); // already registered
    expect(find('Society Coding Challenge'), isNull); // posted 10 days ago
    expect(find('Dance Company'), isNull); // not a member
    expect(find('Clinical duty'), isNull); // another department
    expect(find('HUEFEST'), isNull); // real DCS posts are older than 7 days
    expect(find('INNOVATION AND EXCELLENCE'), isNull); // School News stays out
  });

  test('an event notice opens the event page', () async {
    final n = (await home.loadNotifications(mockStudent))
        .singleWhere((n) => n.title.startsWith('New event: CSS General Assembly'));
    expect(n.kind, NotificationKind.event);
    expect(n.route, '/life/events/ev1');
  });

  test("teacher: gets the same news, but not events they manage", () async {
    final bell = await titles(mockTeacher);
    expect(bell, contains('New announcement: Midterm examination schedule posted'));
    expect(bell.where((t) => t.startsWith('New event: Department Assembly')), isEmpty);
    // The old notice pointed at a deleted post; it now opens the event.
    final n = (await home.loadNotifications(mockTeacher))
        .singleWhere((n) => n.title.startsWith('Department Assembly is in 3 days'));
    expect(n.route, '/life/events/ev2');
  });

  test('an event published in this preview notifies students, not its author', () async {
    await campus.saveEvent(mockTeacher,
        publish: true,
        title: 'Mock Hackathon',
        start: now.add(const Duration(days: 4)),
        end: now.add(const Duration(days: 4, hours: 3)),
        venue: 'Saint Theodore Hall · Lab 1',
        audience: 'Department of Computer Studies');
    expect(await titles(mockStudent), contains('New event: Mock Hackathon · Tue, 3 Nov'));
    expect((await titles(mockTeacher)).where((t) => t.contains('Mock Hackathon')), isEmpty);
  });
}
