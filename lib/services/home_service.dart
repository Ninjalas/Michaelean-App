import 'dart:async';

import '../mock/mock_home.dart';
import '../models/attendance.dart';
import '../models/campus.dart';
import '../models/feed.dart';
import '../models/user_profile.dart';
import 'campus_service.dart';
import 'notification_prefs.dart';
import '../utils/dates.dart';

/// Where Home content comes from. Screens use this, not mock data directly.
abstract class HomeService {
  Future<HomeFeed> loadHome(UserProfile user);
  Future<Post?> findPost(String id);
  Future<List<AppNotification>> loadNotifications(UserProfile user);

  /// Marks these notifications read for [user].
  Future<void> markNotificationsRead(UserProfile user, Iterable<String> ids);

  /// Unread notifications the bell shows (switched-off types don't count).
  Future<int> countUnread(UserProfile user);

  /// Posts to the campus feed, or edits [postId] (the user's own post). Needs
  /// [Permission.postToCampusFeed], or for a club post ([orgId]) being that
  /// club's adviser. Preview only. [audience] is a tag label and [classId] a
  /// class; both null → everyone.
  Future<Post> savePost(
    UserProfile user, {
    String? postId,
    String? orgId,
    required PostKind kind,
    required String title,
    required String body,
    String? audience,
    String? classId,
    required String sentTo,
    bool urgent = false,
    List<String> images = const [], // the first is the cover
  });

  /// Deletes the user's own post.
  Future<void> deletePost(UserProfile user, String postId);

  /// Posts made for a club in this preview that [user] may see (its advisers
  /// see them all), newest first.
  Future<List<Post>> loadClubPosts(UserProfile user, String orgId);
}

/// Photos one post can have (decided 2026-10-30).
const maxPostPhotos = 4;

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
    final classes = await campus.loadClasses(user);
    final canSee = _audienceOf(user, classes);
    final visible = _allPosts(now)
        .where((p) => p.authorId == user.id || canSee(p))
        .toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    List<Post> ofKind(PostKind k) => visible.where((p) => p.kind == k).toList();
    // Urgent announcements first; each part stays newest first.
    final announcements = [
      ...ofKind(PostKind.announcement).where((p) => p.urgent),
      ...ofKind(PostKind.announcement).where((p) => !p.urgent),
    ];

    final news = ofKind(PostKind.schoolNews);
    final personal = visible.where((p) => const {
          PostKind.departmentNews,
          PostKind.organizationNews,
          PostKind.eventUpdate,
          PostKind.campusUpdate,
        }.contains(p.kind));
    // Urgent first (pinned), then the rest; each part stays newest first.
    final campusFeed = [
      ...personal.where((p) => p.urgent),
      ...personal.where((p) => !p.urgent),
    ];

    if (user.role == UserRole.student) {
      final records = await campus.loadMyAttendance(user);
      final present = records.where((r) => r.mark == AttendanceMark.present).length;
      // Clearance stat and tasks come from the Clearance screen's data.
      final clearance = (await campus.loadClearanceView(user)).active;
      // Event stats come from official records (registration isn't attendance):
      // attended ÷ past events the student registered for or attended.
      final history = await campus.loadEventHistory(user);
      final pastMine = (await campus.loadEvents(user, EventList.mine))
          .where((d) => !d.event.end.isAfter(now))
          .toList();
      final attendedPast = pastMine.where((d) => d.record != null).length;
      const studentTodo = {ClearanceStatus.needsCorrection, ClearanceStatus.actionRequired};
      return HomeFeed(
        attendance: AttendanceSummary(
          // Finalized records only (spec §7.2).
          classPercent: records.isEmpty ? 0 : (present * 100 / records.length).round(),
          eventPercent: pastMine.isEmpty ? 0 : (attendedPast * 100 / pastMine.length).round(),
          eventsCompleted: history.length,
          requirementsCleared: clearance?.cleared ?? 0,
          requirementsTotal: clearance?.applicable.length ?? 0,
        ),
        nextClass: nextClass(classes, now),
        tasks: [
          for (final i in clearance?.items ?? const <ClearanceItem>[])
            if (studentTodo.contains(i.status))
              PendingTask(
                id: 'clearance-${i.id}',
                title: '${i.office} clearance',
                detail: i.reason ?? i.instructions,
                status: i.status == ClearanceStatus.needsCorrection
                    ? TaskStatus.needsCorrection
                    : TaskStatus.actionRequired,
                route: '/life/clearance/${i.id}',
              ),
          ...mockTasks,
        ],
        announcements: announcements,
        featuredNews: news.isEmpty ? null : news.first,
        moreNews: news.skip(1).toList(),
        campusFeed: campusFeed,
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
      announcements: announcements,
      featuredNews: news.isEmpty ? null : news.first,
      moreNews: news.skip(1).toList(),
      campusFeed: campusFeed,
    );
  }

  @override
  Future<List<AppNotification>> loadNotifications(UserProfile user) async {
    await Future.delayed(delay);
    if (fail) throw Exception('Mock load failure');
    final now = clock();
    final canSee = _audienceOf(user, await campus.loadClasses(user));
    final myTags = user.tags.map((t) => t.label).toSet();
    // The bell shows what's new from the last 7 days (decided 2026-10-30).
    final since = now.subtract(const Duration(days: 7));
    bool isNew(DateTime t) => t.isAfter(since) && !t.isAfter(now);
    const postKinds = {
      PostKind.announcement: NotificationKind.announcement,
      PostKind.departmentNews: NotificationKind.news,
      PostKind.organizationNews: NotificationKind.organization,
    };
    final events = await campus.loadEvents(user, EventList.discover);
    final all = [
      ...user.role == UserRole.student
          ? mockNotifications(now)
          : mockTeacherNotifications(now),
      // New announcements, department news, and club posts (members only) the
      // user may see, not their own. Deleting a post removes its notice.
      for (final p in _allPosts(now))
        if (postKinds.containsKey(p.kind) &&
            p.authorId != user.id &&
            canSee(p) &&
            (p.kind != PostKind.organizationNews || myTags.contains(p.source)) &&
            isNew(_notifiedAt[p.id] ?? p.publishedAt))
          AppNotification(
            // A new id per version, so an edit shows as unread again.
            id: 'post-${p.id}-v${_postVersions[p.id] ?? 0}',
            kind: postKinds[p.kind]!,
            title: _noticeTitle(p),
            time: _notifiedAt[p.id] ?? p.publishedAt,
            postId: p.id,
            urgent: p.urgent,
          ),
      // New events the user can join (the Events page's Discover list), not
      // the ones they manage or already registered for.
      for (final d in events)
        if (d.event.postedAt != null && isNew(d.event.postedAt!) && !d.canManage && !d.registered)
          AppNotification(
            id: 'event-${d.event.id}',
            kind: NotificationKind.event,
            title: 'New event: ${d.event.title} · ${formatShortDate(d.event.start)}',
            time: d.event.postedAt!,
            route: '/life/events/${d.event.id}',
          ),
      // Accepted, declined, added, or removed by a club adviser; registered by
      // a teacher's invitation.
      ...await campus.loadMembershipNotices(user),
      // Connect requests waiting, and requests accepted.
      ...await campus.loadConnectNotices(user),
    ]..sort((a, b) => b.time.compareTo(a.time));
    final read = await _readFor(user.id);
    return [for (final n in all) n.read || read.contains(n.id) ? n.markedRead() : n];
  }

  /// "New announcement: …", "Computer Science Society: …", "Urgent: …", or "Updated: …".
  static String _noticeTitle(Post p) {
    final from = p.kind == PostKind.announcement ? '' : '${p.source}: ';
    if (p.edited) return 'Updated: $from${p.title}';
    if (p.urgent) return 'Urgent: $from${p.title}';
    return p.kind == PostKind.announcement ? 'New announcement: ${p.title}' : '$from${p.title}';
  }

  /// Read notification ids per user: loaded once from this device, then kept here.
  final _read = <String, Future<Set<String>>>{};

  Future<Set<String>> _readFor(String userId) =>
      _read[userId] ??= NotificationPrefs.readIds(userId);

  @override
  Future<void> markNotificationsRead(UserProfile user, Iterable<String> ids) async {
    final read = await _readFor(user.id);
    read.addAll(ids);
    // Saving is best effort; if storage is blocked, it stays read until reload.
    unawaited(NotificationPrefs.saveReadIds(user.id, read));
  }

  @override
  Future<int> countUnread(UserProfile user) async {
    final (all, muted) = await (loadNotifications(user), NotificationPrefs.muted()).wait;
    return all.where((n) => !n.read && NotificationPrefs.shows(n, muted)).length;
  }

  @override
  Future<Post?> findPost(String id) async {
    await Future.delayed(delay);
    if (fail) throw Exception('Mock load failure');
    for (final p in _allPosts(clock())) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Posts made in this preview, newest first. Kept in memory only.
  final _posted = <Post>[];
  int _nextPostId = 0;
  final _postVersions = <String, int>{}; // edits per post
  final _notifiedAt = <String, DateTime>{}; // last post or edit, for its notification

  /// Whether [user] is in a post's audience: its tag (department, organization)
  /// and its class, when it has them.
  bool Function(Post) _audienceOf(UserProfile user, List<ClassSession> classes) {
    final myTags = user.tags.map((t) => t.label).toSet();
    final myClasses = classes.map((c) => c.classId).toSet();
    return (p) =>
        (p.audience == null || myTags.contains(p.audience)) &&
        (p.classId == null || myClasses.contains(p.classId));
  }

  List<Post> _allPosts(DateTime now) => [..._posted, ...mockPosts(now)];

  @override
  Future<Post> savePost(
    UserProfile user, {
    String? postId,
    String? orgId,
    required PostKind kind,
    required String title,
    required String body,
    String? audience,
    String? classId,
    required String sentTo,
    bool urgent = false,
    List<String> images = const [],
  }) async {
    await Future.delayed(delay);
    if (fail) throw Exception('Mock save failure');
    // A club post needs the club's adviser; anything else the posting permission.
    final club = orgId == null
        ? null
        : (await campus.loadAdvisedClubs(user)).where((c) => c.org.id == orgId).firstOrNull?.org;
    if (orgId != null && club == null) throw StateError("You don't advise this club.");
    if (club == null && !user.can(Permission.postToCampusFeed)) {
      throw StateError("You don't have permission to post.");
    }
    if (title.trim().isEmpty || body.trim().isEmpty) {
      throw ArgumentError('Add a title and a message.');
    }
    if (images.length > maxPostPhotos) throw ArgumentError('Add up to $maxPostPhotos photos.');
    final i = postId == null ? -1 : _posted.indexWhere((p) => p.id == postId);
    if (postId != null && (i < 0 || _posted[i].authorId != user.id)) {
      throw StateError('You can only edit your own posts.');
    }
    final post = Post(
      id: postId ?? 'mine-${++_nextPostId}',
      kind: club != null ? PostKind.organizationNews : kind,
      title: title.trim(),
      body: body.trim(),
      source: club?.name ?? user.fullName,
      sourceImage: club != null ? club.logoAsset : user.photoAsset,
      orgId: club?.id,
      imageAsset: images.firstOrNull,
      extraImages: images.skip(1).toList(),
      publishedAt: i < 0 ? clock() : _posted[i].publishedAt,
      urgent: urgent,
      audience: audience,
      classId: classId,
      authorId: user.id,
      sentTo: sentTo,
      edited: i >= 0,
    );
    if (i < 0) {
      _posted.insert(0, post);
    } else {
      _posted[i] = post;
      _postVersions[post.id] = (_postVersions[post.id] ?? 0) + 1;
    }
    _notifiedAt[post.id] = clock();
    return post;
  }

  @override
  Future<List<Post>> loadClubPosts(UserProfile user, String orgId) async {
    await Future.delayed(delay);
    if (fail) throw Exception('Mock load failure');
    final advises = (await campus.loadAdvisedClubs(user)).any((c) => c.org.id == orgId);
    final canSee = _audienceOf(user, await campus.loadClasses(user));
    return [
      for (final p in _posted)
        if (p.orgId == orgId && (advises || p.authorId == user.id || canSee(p))) p,
    ];
  }

  @override
  Future<void> deletePost(UserProfile user, String postId) async {
    await Future.delayed(delay);
    if (fail) throw Exception('Mock save failure');
    final i = _posted.indexWhere((p) => p.id == postId && p.authorId == user.id);
    if (i < 0) throw StateError('You can only delete your own posts.');
    _posted.removeAt(i);
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
