import 'attendance.dart';
import 'event_record.dart';
import 'feed.dart';

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

  /// The user's official attendance record for this event, if any.
  final EventRecord? record;

  /// For managers: whether attendance was finalized, and how many attended.
  final bool attendanceFinalized;
  final int attendedCount;

  const EventDetail({
    required this.event,
    required this.registered,
    this.invited = false,
    required this.going,
    required this.canManage,
    this.closedReason,
    this.record,
    this.attendanceFinalized = false,
    this.attendedCount = 0,
  });
}

/// Which list of events to load.
enum EventList {
  discover, // published upcoming events the student is eligible for
  mine, // events the student registered for, upcoming and past
  managed, // every event the user may manage: upcoming, past, drafts
}

/// Event check-in for its managers: who registered and who was scanned.
class EventCheckIn {
  final CampusEvent event;
  final List<RosterStudent> registrants; // registered students the app knows
  final Set<String> present; // scanned student ids
  final bool finalized;

  const EventCheckIn({
    required this.event,
    required this.registrants,
    required this.present,
    required this.finalized,
  });

  List<RosterStudent> get unchecked =>
      registrants.where((s) => !present.contains(s.id)).toList();
}

/// A campus office to contact for help (Help & Support).
class SupportContact {
  final String office;
  final String helpsWith;
  final String place;
  final String hours;
  final String contact;

  const SupportContact({
    required this.office,
    required this.helpsWith,
    required this.place,
    required this.hours,
    required this.contact,
  });
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

/// A departmental society belongs to one department; a club is open to
/// the whole school (spec §7.4). A department is not its society.
enum OrgKind { society, club }

/// A regular meeting on an organization's schedule.
class OrgMeeting {
  final String title;
  final String when; // e.g. "Every Friday · 3:00 PM"
  final String place;

  const OrgMeeting({required this.title, required this.when, required this.place});
}

/// An officer as listed on the organization page. Listing someone here
/// doesn't give them permissions (spec §12).
class OrgOfficer {
  final String name;
  final String position;
  final String? photoAsset;

  const OrgOfficer({required this.name, required this.position, this.photoAsset});
}

class Organization {
  final String id;
  final String name; // matches the organization tag label exactly
  final String? logoAsset; // null → initials
  final String? coverAsset; // null → plain tinted cover
  final int memberCount;
  final OrgKind kind;

  /// For a society: the department it belongs to. Null for clubs.
  final String? department;
  final String about;
  final List<OrgMeeting> meetings;
  final List<OrgOfficer> officers;

  const Organization({
    required this.id,
    required this.name,
    this.logoAsset,
    this.coverAsset,
    required this.memberCount,
    this.kind = OrgKind.club,
    this.department,
    this.about = '',
    this.meetings = const [],
    this.officers = const [],
  });
}

/// The Organizations directory (spec §7.4), in its three groups.
class OrgDirectory {
  final List<Organization> society; // the user's departmental society, if any
  final List<Organization> clubs; // approved school-wide clubs
  final List<Organization> mine; // confirmed memberships

  const OrgDirectory({required this.society, required this.clubs, required this.mine});
}

/// An organization page as one user sees it.
class OrganizationPage {
  final Organization org;
  final bool isMember; // a confirmed membership tag, never self-assigned
  final bool requested; // asked to join in this preview; still not a member
  final List<EventDetail> events; // upcoming events the user may see
  final List<Post> news; // posts the user may see, newest first
  final int membersOnlyHidden; // events and posts hidden from non-members

  const OrganizationPage({
    required this.org,
    required this.isMember,
    required this.requested,
    required this.events,
    required this.news,
    required this.membersOnlyHidden,
  });
}

/// Clearance statuses (spec §7.5). Action required: the student has
/// something to do for the first time. Needs correction: staff returned a
/// submission with a reason. (Proposed meanings, open decision 8.)
enum ClearanceStatus {
  notStarted,
  actionRequired,
  inReview,
  needsCorrection,
  cleared,
  onHold,
  notApplicable,
}

/// One requirement in a clearance period, e.g. Library · Book returns.
class ClearanceItem {
  final String id;
  final String office; // who processes it, e.g. "Library"
  final String title;
  final String instructions; // what the student has to do
  final ClearanceStatus status;
  final String? reason; // why staff returned it or put it on hold
  final bool evidenceRequired;

  const ClearanceItem({
    required this.id,
    required this.office,
    required this.title,
    required this.instructions,
    required this.status,
    this.reason,
    this.evidenceRequired = false,
  });
}

/// An active clearance period with the student's requirements.
class ClearancePeriod {
  final String name; // e.g. "1st Semester Clearance"
  final DateTime deadline;
  final List<ClearanceItem> items;

  const ClearancePeriod({required this.name, required this.deadline, required this.items});

  /// Not applicable items don't count toward the total.
  List<ClearanceItem> get applicable =>
      items.where((i) => i.status != ClearanceStatus.notApplicable).toList();

  int get cleared => items.where((i) => i.status == ClearanceStatus.cleared).length;
}

/// A finished clearance from an earlier period.
class PastClearance {
  final String name;
  final DateTime completedOn;

  const PastClearance({required this.name, required this.completedOn});
}

/// Everything on the student's Clearance screen.
class ClearanceView {
  final ClearancePeriod? active; // null → Clearance Unavailable
  final List<PastClearance> past;

  const ClearanceView({required this.active, required this.past});
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

/// What staff may see about a student: identification only (spec §12).
class ClearanceStudent {
  final String id;
  final String name;
  final String maskedId;
  final String section;
  final String? photoAsset;
  final String qrToken; // random mock token; lets the mock scanner simulate a scan

  const ClearanceStudent({
    required this.id,
    required this.name,
    required this.maskedId,
    required this.section,
    this.photoAsset,
    required this.qrToken,
  });
}

/// One student's requirements for the staff member's office.
class ClearanceCase {
  final ClearanceStudent student;
  final List<ClearanceItem> items; // only this office's requirements

  const ClearanceCase({required this.student, required this.items});
}

/// The staff verification desk (spec §9.3).
class ClearanceDesk {
  final String office;
  final String periodName;
  final List<ClearanceCase> pending; // students with something In review

  const ClearanceDesk({required this.office, required this.periodName, required this.pending});
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
