import '../mock/mock_campus.dart';
import '../mock/mock_home.dart';
import '../models/campus.dart';
import '../models/feed.dart';
import '../models/user_profile.dart';

/// Where class, event, organization, and clearance data comes from (spec §7,
/// §9). Screens use this, not mock data directly.
abstract class CampusService {
  /// The user's classes that haven't ended yet, earliest first.
  Future<List<ClassSession>> loadClasses(UserProfile user);

  /// Published events the user is eligible for, soonest first.
  Future<List<CampusEvent>> loadUpcomingEvents(UserProfile user);

  /// Events the user is allowed to manage, including drafts.
  Future<List<CampusEvent>> loadManagedEvents(UserProfile user);

  /// Organizations the user is a confirmed member of.
  Future<List<Organization>> loadMyOrganizations(UserProfile user);

  /// The active clearance period; null when there is none.
  Future<ClearanceSummary?> loadClearance(UserProfile user);

  /// The clearance office the user processes; null when not assigned.
  Future<ClearanceOffice?> loadClearanceOffice(UserProfile user);
}

class MockCampusService implements CampusService {
  final Duration delay; // pretend network time, so loading states show
  final bool fail; // tests use this to check the error state
  final DateTime Function() clock;

  MockCampusService({
    this.delay = const Duration(milliseconds: 500),
    this.fail = false,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  Future<void> _wait() async {
    await Future.delayed(delay);
    if (fail) throw Exception('Mock load failure');
  }

  @override
  Future<List<ClassSession>> loadClasses(UserProfile user) async {
    await _wait();
    final now = clock();
    final all = user.role == UserRole.student ? mockStudentClasses(now) : mockTeacherClasses(now);
    // Today's ended classes stay: the hub shows the whole day.
    final today = DateTime(now.year, now.month, now.day);
    return all.where((c) => !c.start.isBefore(today)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  @override
  Future<List<CampusEvent>> loadUpcomingEvents(UserProfile user) async {
    await _wait();
    final now = clock();
    final myTags = user.tags.map((t) => t.label).toSet();
    return mockEvents(now)
        .where((e) =>
            e.status == EventStatus.published &&
            e.start.isAfter(now) &&
            (e.audience == null || myTags.contains(e.audience)))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  @override
  Future<List<CampusEvent>> loadManagedEvents(UserProfile user) async {
    await _wait();
    if (!user.can(Permission.manageEvents)) return const [];
    final now = clock();
    return mockEvents(now)
        .where((e) => e.managerIds.contains(user.id) && e.start.isAfter(now))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  @override
  Future<List<Organization>> loadMyOrganizations(UserProfile user) async {
    await _wait();
    // Confirmed memberships are the user's organization tags (spec §5).
    final memberOf = user.tags
        .where((t) => t.kind == TagKind.organization)
        .map((t) => t.label)
        .toSet();
    return mockOrganizations.where((o) => memberOf.contains(o.name)).toList();
  }

  @override
  Future<ClearanceSummary?> loadClearance(UserProfile user) async {
    await _wait();
    return mockClearanceFor(user.id, clock());
  }

  @override
  Future<ClearanceOffice?> loadClearanceOffice(UserProfile user) async {
    await _wait();
    if (!user.can(Permission.processClearance)) return null;
    return mockClearanceOffices[user.id];
  }
}
