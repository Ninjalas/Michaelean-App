/// Draft and published are separate states (spec §9.2). Only published
/// events are shown to students.
enum EventStatus { draft, published }

class CampusEvent {
  final String id;
  final String title;
  final String host; // e.g. "Computer Science Society"
  final String? hostLogo;
  final DateTime start;
  final String venue;
  final String? coverAsset; // null → placeholder tile
  final EventStatus status;

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
    required this.venue,
    this.coverAsset,
    this.status = EventStatus.published,
    this.audience,
    this.managerIds = const {},
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
