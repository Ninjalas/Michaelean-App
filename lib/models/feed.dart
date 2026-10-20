enum PostKind { announcement, schoolNews, departmentNews, organizationNews, eventUpdate }

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

/// Everything Student Home shows, already split into sections.
class HomeFeed {
  final AttendanceSummary attendance;
  final List<PendingTask> tasks;
  final List<Post> announcements;
  final Post? featuredNews;
  final List<Post> moreNews;
  final List<Post> forYou;
  final List<AppNotification> notifications;

  const HomeFeed({
    required this.attendance,
    required this.tasks,
    required this.announcements,
    required this.featuredNews,
    required this.moreNews,
    required this.forYou,
    required this.notifications,
  });

  bool get isEmpty =>
      tasks.isEmpty && announcements.isEmpty && featuredNews == null && forYou.isEmpty;
}
