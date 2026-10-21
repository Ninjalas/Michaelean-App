import '../mock/mock_home.dart';
import '../models/attendance.dart';
import '../models/feed.dart';
import '../models/user_profile.dart';
import 'campus_service.dart';

/// Where Home content comes from. Screens use this, not mock data directly.
abstract class HomeService {
  Future<HomeFeed> loadHome(UserProfile user);
  Future<Post?> findPost(String id);
  Future<List<AppNotification>> loadNotifications(UserProfile user);
}

/// The class happening now or next; null when nothing is scheduled ahead.
ClassSession? nextClass(List<ClassSession> classes, DateTime now) {
  final ahead = classes.where((c) => c.end.isAfter(now)).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  return ahead.isEmpty ? null : ahead.first;
}

class MockHomeService implements HomeService {
  final Duration delay; // pretend network time, so loading states show
  final bool fail; // tests use this to check the error state
  final DateTime Function() clock;

  /// Classes and attendance come from here, so Home always agrees with the
  /// Class screens (e.g. a finalized session stops being a task).
  late final CampusService campus;

  MockHomeService({
    this.delay = const Duration(milliseconds: 500),
    this.fail = false,
    DateTime Function()? clock,
    CampusService? campus,
  }) : clock = clock ?? DateTime.now {
    this.campus = campus ?? MockCampusService(delay: Duration.zero, clock: this.clock);
  }

  @override
  Future<HomeFeed> loadHome(UserProfile user) async {
    await Future.delayed(delay);
    if (fail) throw Exception('Mock load failure');

    final now = clock();
    final myTags = user.tags.map((t) => t.label).toSet();
    final visible = mockPosts(now)
        .where((p) => p.audience == null || myTags.contains(p.audience))
        .toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    List<Post> ofKind(PostKind k) => visible.where((p) => p.kind == k).toList();

    final news = ofKind(PostKind.schoolNews);
    final personal = visible.where((p) => const {
          PostKind.departmentNews,
          PostKind.organizationNews,
          PostKind.eventUpdate,
        }.contains(p.kind));
    // Urgent first (pinned), then the rest; each part stays newest first.
    final campusFeed = [
      ...personal.where((p) => p.urgent),
      ...personal.where((p) => !p.urgent),
    ];

    final classes = await campus.loadClasses(user);

    if (user.role == UserRole.student) {
      final records = await campus.loadMyAttendance(user);
      final present = records.where((r) => r.mark == AttendanceMark.present).length;
      final a = mockAttendance;
      return HomeFeed(
        attendance: AttendanceSummary(
          // Finalized records only (spec §7.2).
          classPercent: records.isEmpty ? 0 : (present * 100 / records.length).round(),
          eventPercent: a.eventPercent,
          eventsCompleted: a.eventsCompleted,
          requirementsCleared: a.requirementsCleared,
          requirementsTotal: a.requirementsTotal,
        ),
        nextClass: nextClass(classes, now),
        tasks: mockTasks,
        announcements: ofKind(PostKind.announcement),
        featuredNews: news.isEmpty ? null : news.first,
        moreNews: news.skip(1).toList(),
        campusFeed: campusFeed,
        notifications: mockNotifications(now),
      );
    }

    final unfinalized = classes.where((c) => c.awaitingFinalization).toList();
    return HomeFeed(
      today: TodayOverview(
        classesToday: classes.where((c) => _sameDay(c.start, now)).length,
        sessionsToFinalize: unfinalized.length,
        upcomingEvents: mockUpcomingEventCount,
      ),
      nextClass: nextClass(classes, now),
      todayClasses: classes.where((c) => _sameDay(c.start, now)).toList()
        ..sort((a, b) => a.start.compareTo(b.start)),
      changes: ofKind(PostKind.scheduleChange),
      tasks: [
        for (final c in unfinalized)
          PendingTask(
            id: 'finalize-${c.id}',
            title: 'Finalize attendance',
            detail: '${c.subject} · ${c.section}',
            status: TaskStatus.actionRequired,
            route: '/attendance/${c.id}/review',
          ),
        ...mockTeacherTasks,
      ],
      announcements: ofKind(PostKind.announcement),
      featuredNews: news.isEmpty ? null : news.first,
      moreNews: news.skip(1).toList(),
      campusFeed: campusFeed,
      notifications: mockTeacherNotifications(now),
    );
  }

  @override
  Future<List<AppNotification>> loadNotifications(UserProfile user) async {
    await Future.delayed(delay);
    if (fail) throw Exception('Mock load failure');
    return user.role == UserRole.student
        ? mockNotifications(clock())
        : mockTeacherNotifications(clock());
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

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
