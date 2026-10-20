import '../mock/mock_home.dart';
import '../models/feed.dart';
import '../models/user_profile.dart';

/// Where Home content comes from. Screens use this, not mock data directly.
abstract class HomeService {
  Future<HomeFeed> loadStudentHome(UserProfile user);
  Future<Post?> findPost(String id);
  Future<List<AppNotification>> loadNotifications(UserProfile user);
}

class MockHomeService implements HomeService {
  final Duration delay; // pretend network time, so loading states show
  final bool fail; // tests use this to check the error state
  final DateTime Function() clock;

  MockHomeService({
    this.delay = const Duration(milliseconds: 500),
    this.fail = false,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  @override
  Future<HomeFeed> loadStudentHome(UserProfile user) async {
    await Future.delayed(delay);
    if (fail) throw Exception('Mock load failure');

    final now = clock();
    final myTags = user.tags.map((t) => t.label).toSet();
    final visible = mockPosts(now)
        .where((p) => p.audience == null || myTags.contains(p.audience))
        .toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    final news = visible.where((p) => p.kind == PostKind.schoolNews).toList();
    final personal = visible.where((p) => const {
          PostKind.departmentNews,
          PostKind.organizationNews,
          PostKind.eventUpdate,
        }.contains(p.kind));
    // Urgent first, then the rest; each part stays newest first.
    final forYou = [
      ...personal.where((p) => p.urgent),
      ...personal.where((p) => !p.urgent),
    ];

    return HomeFeed(
      attendance: mockAttendance,
      tasks: mockTasks,
      announcements: visible.where((p) => p.kind == PostKind.announcement).toList(),
      featuredNews: news.isEmpty ? null : news.first,
      moreNews: news.skip(1).toList(),
      forYou: forYou,
      notifications: mockNotifications(now),
    );
  }

  @override
  Future<List<AppNotification>> loadNotifications(UserProfile user) async {
    await Future.delayed(delay);
    if (fail) throw Exception('Mock load failure');
    return mockNotifications(clock());
  }

  @override
  Future<Post?> findPost(String id) async {
    await Future.delayed(delay);
    for (final p in mockPosts(clock())) {
      if (p.id == id) return p;
    }
    return null;
  }
}
