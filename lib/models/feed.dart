enum PostKind {
  announcement,
  schoolNews,
  departmentNews,
  organizationNews,
  eventUpdate,
  scheduleChange,
}

class Post {
  final String id;
  final PostKind kind;
  final String title;
  final String body;
  final String source; // e.g. "Registrar's Office", "Computer Science Society"
  final String? sourceImage; // org logo, if any
  final String? imageAsset;
  final DateTime publishedAt;
  final bool urgent;

  /// Tag label a user must have to see this post (e.g. a department or
  /// organization name). Null means everyone at the institution.
  final String? audience;

  const Post({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.source,
    this.sourceImage,
    this.imageAsset,
    required this.publishedAt,
    this.urgent = false,
    this.audience,
  });
}

/// Uses the same names as the clearance statuses (spec §7.5).
enum TaskStatus { actionRequired, inReview, needsCorrection }

class PendingTask {
  final String id;
  final String title;
  final String detail;
  final TaskStatus status;

  const PendingTask({
    required this.id,
    required this.title,
    required this.detail,
    required this.status,
  });
}

class AttendanceSummary {
  final int classPercent;
  final int eventPercent;
  final int eventsCompleted;
  final int requirementsCleared;
  final int requirementsTotal;

  const AttendanceSummary({
    required this.classPercent,
    required this.eventPercent,
    required this.eventsCompleted,
    required this.requirementsCleared,
    required this.requirementsTotal,
  });
}

class AppNotification {
  final String id;
  final String title;
  final DateTime time;
  final String? postId; // opens this post; null → its feature isn't built yet

  const AppNotification({
    required this.id,
    required this.title,
    required this.time,
    this.postId,
  });
}

class ClassSession {
  final String id;
  final String subject; // e.g. "CS 301 · Data Structures"
  final String section;
  final DateTime start;
  final DateTime end;
  final String room;

  /// Attendance was taken but the teacher hasn't finalized it yet. Only this
  /// creates an attendance task; a scheduled class alone does not (spec §8).
  final bool awaitingFinalization;

  const ClassSession({
    required this.id,
    required this.subject,
    required this.section,
    required this.start,
    required this.end,
    required this.room,
    this.awaitingFinalization = false,
  });
}

/// Teacher Home's "Today's Overview" (spec §8).
class TodayOverview {
  final int classesToday;
  final int sessionsToFinalize;
  final int upcomingEvents;

  const TodayOverview({
    required this.classesToday,
    required this.sessionsToFinalize,
    required this.upcomingEvents,
  });
}

/// Everything Home shows, already split into sections. Students get
/// [attendance]; teachers get [today], [nextClass], and [changes].
class HomeFeed {
  final AttendanceSummary? attendance;
  final TodayOverview? today;
  final ClassSession? nextClass;
  final List<Post> changes; // schedule and classroom changes
  final List<PendingTask> tasks;
  final List<Post> announcements;
  final Post? featuredNews;
  final List<Post> moreNews;
  final List<Post> forYou;
  final List<AppNotification> notifications;

  const HomeFeed({
    this.attendance,
    this.today,
    this.nextClass,
    this.changes = const [],
    required this.tasks,
    required this.announcements,
    required this.featuredNews,
    required this.moreNews,
    required this.forYou,
    required this.notifications,
  });

  bool get isEmpty =>
      tasks.isEmpty &&
      changes.isEmpty &&
      announcements.isEmpty &&
      featuredNews == null &&
      forYou.isEmpty;
}
