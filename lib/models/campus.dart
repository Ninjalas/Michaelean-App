/// Draft and published are separate states (spec §9.2). Only published
/// events are shown to students. Cancelled events stay visible to people
/// who registered, marked as cancelled.
enum EventStatus { draft, published, cancelled }

class CampusEvent {
  final String id;
  final String title;
  final String host; // e.g. "Computer Science Society"
  final String? hostLogo;
  final DateTime start;
  final DateTime end;
  final String venue;
  final String? coverAsset; // null → placeholder tile
  final EventStatus status;
  final String description;

  /// Last day to register; null means until the event starts.
  final DateTime? deadline;

  /// Maximum registrations; null means no limit.
  final int? capacity;

  /// Set when a published event's time or venue changed, so the change is
  /// clearly shown (spec §9.2).
  final String? updateNote;

  /// Tag label a user must have to see this event (a department or
  /// organization). Null means school-wide.
  final String? audience;

  /// Users allowed to manage this event (spec §12). Creating an event is
  /// not the same as hosting it.
  final Set<String> managerIds;

  const CampusEvent({
    required this.id,
    required this.title,
    required this.host,
    this.hostLogo,
    required this.start,
    required this.end,
    required this.venue,
    this.coverAsset,
    this.status = EventStatus.published,
    this.description = '',
    this.deadline,
    this.capacity,
    this.updateNote,
    this.audience,
    this.managerIds = const {},
  });

  CampusEvent copyWith({EventStatus? status}) => CampusEvent(
        id: id,
        title: title,
        host: host,
        hostLogo: hostLogo,
        start: start,
        end: end,
        venue: venue,
        coverAsset: coverAsset,
        status: status ?? this.status,
        description: description,
        deadline: deadline,
        capacity: capacity,
        updateNote: updateNote,
        audience: audience,
        managerIds: managerIds,
      );
}

/// An event as one user sees it: their registration and what they may do.
class EventDetail {
  final CampusEvent event;
  final bool registered;
  final bool invited; // registered by a teacher's invitation
  final int going; // registrations, not attendance
  final bool canManage;

  /// Why this user can't register right now (full, closed, ineligible…);
  /// null when registration is open to them.
  final String? closedReason;

  const EventDetail({
    required this.event,
    required this.registered,
    this.invited = false,
    required this.going,
    required this.canManage,
    this.closedReason,
  });
}

/// Which list of events to load.
enum EventList {
  discover, // published upcoming events the student is eligible for
  mine, // events the student registered for, upcoming and past
  managed, // every event the user may manage: upcoming, past, drafts
}

/// A registered student, as the event's managers see them.
class EventRegistrant {
  final String name;
  final String maskedId;
  final String? photoAsset;
  final bool invited;

  const EventRegistrant({
    required this.name,
    required this.maskedId,
    this.photoAsset,
    required this.invited,
  });
}

class Organization {
  final String id;
  final String name; // matches the organization tag label exactly
  final String? logoAsset; // null → initials
  final int memberCount;

  const Organization({
    required this.id,
    required this.name,
    this.logoAsset,
    required this.memberCount,
  });
}

/// A student's progress in the active clearance period (spec §7.5).
class ClearanceSummary {
  final String periodName; // e.g. "1st Semester Clearance"
  final DateTime deadline;
  final int cleared;
  final int total;
  final int needsCorrection;

  const ClearanceSummary({
    required this.periodName,
    required this.deadline,
    required this.cleared,
    required this.total,
    this.needsCorrection = 0,
  });
}

/// The clearance office a staff member is assigned to (spec §9.3).
class ClearanceOffice {
  final String name; // e.g. "Library"
  final int pendingCount;

  const ClearanceOffice({required this.name, required this.pendingCount});
}

/// The first problem with an event form, or null when it can be saved.
/// Shared by the form (to explain a disabled button) and the service (which
/// checks again, since frontend checks aren't security).
String? eventFormProblem({
  required String title,
  required String venue,
  required DateTime start,
  required DateTime end,
  DateTime? deadline,
  int? capacity,
  int registered = 0,
  required bool publishing,
  required DateTime now,
}) {
  if (title.trim().isEmpty) return 'Enter an event name.';
  if (venue.trim().isEmpty) return 'Enter a venue.';
  if (!end.isAfter(start)) return 'The event must end after it starts.';
  if (deadline != null && deadline.isAfter(start)) {
    return 'The registration deadline must be before the event starts.';
  }
  if (capacity != null && capacity < 1) return 'Capacity must be at least 1.';
  if (capacity != null && capacity < registered) {
    return 'Capacity is below the $registered students already registered.';
  }
  if (publishing && !start.isAfter(now)) return 'A published event must start in the future.';
  return null;
}
