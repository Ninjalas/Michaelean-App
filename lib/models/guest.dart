/// Registration and guest list data (spec §7.3).
///
/// Registration is not attendance: nothing here counts toward event history
/// or metrics. Only official attendance confirmation does.

/// Programs offered in the registration dropdown. Sample list for the
/// prototype; the school's official program list replaces it later.
const registrationCourses = [
  'Nursing',
  'BS Computer Science',
  'BS Information Technology',
  'BS Business Administration',
  'BS Accountancy',
  'BS Psychology',
  'BS Education',
  'BS Engineering',
  'BS Hospitality Management',
  'BS Tourism Management',
  'BS Medical Technology',
];

const registrationYearLevels = ['1st Year', '2nd Year', '3rd Year', '4th Year'];

/// One person on an event's guest list.
class EventGuest {
  final String id; // the user's id
  final String name;
  final String course;
  final String yearLevel;
  final String? photoAsset; // null → initials

  const EventGuest({
    required this.id,
    required this.name,
    required this.course,
    required this.yearLevel,
    this.photoAsset,
  });
}

/// Where the viewer stands with an event's registration.
enum RegistrationState {
  open, // can register
  registered, // already registered
  full, // capacity reached
  closed, // draft, or the event already started
}

/// What anyone who can see the event may know about its guests: a count and
/// a few avatars (spec §7.3). The full list is [EventGuest]s, registered
/// guests and event managers only (mock assumption for open decision 4).
class GuestSummary {
  final int count;
  final List<EventGuest> preview; // a few, for the avatar stack
  final int? capacity; // null → no limit
  final RegistrationState state;
  final bool canViewList;

  const GuestSummary({
    required this.count,
    required this.preview,
    this.capacity,
    required this.state,
    required this.canViewList,
  });
}

enum RegistrationProblem {
  notFound,
  notEligible,
  closed,
  full,
  alreadyRegistered,
  notRegistered,
  invalidCourse,
  invalidYear,
}

/// Why a registration (or cancellation) was refused. [message] is written
/// for the person using the app.
class RegistrationException implements Exception {
  final RegistrationProblem problem;
  final String message;

  const RegistrationException(this.problem, this.message);

  @override
  String toString() => message;
}
