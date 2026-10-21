// MOCK DATA — sample events, organizations, and clearance for the frontend
// prototype. Event names, venues, member counts, and dates are invented.
// The CSS cover image is real and is used as the society's event cover for
// illustration only.

import '../models/campus.dart';
import 'mock_users.dart';

const _css = 'Computer Science Society';
const _dcs = 'Department of Computer Studies';
const _cssLogo = 'assets/images/profiles/css_profile.jpg';
const _cssCover = 'assets/images/profiles/css_coverpage.png';

List<CampusEvent> mockEvents(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  DateTime at(int dayOffset, int hour) => today.add(Duration(days: dayOffset, hours: hour));
  return [
    CampusEvent(
      id: 'ev1',
      title: 'CSS General Assembly',
      host: _css,
      hostLogo: _cssLogo,
      start: at(2, 15),
      end: at(2, 17),
      venue: 'Milagros Limaco Hall',
      coverAsset: _cssCover,
      audience: _css,
      deadline: at(1, 23),
      capacity: 150,
      description: 'Sample description. The society meets to introduce this '
          "semester's officers, plans, and committees. Bring your questions.",
    ),
    CampusEvent(
      id: 'ev2',
      title: 'Department Assembly',
      host: _dcs,
      start: at(3, 14),
      end: at(3, 16),
      venue: "Saint Mary's Conference Center",
      audience: _dcs,
      managerIds: {mockTeacher.id},
      description: 'Sample description. Updates from the department for all '
          'Computer Studies students.',
    ),
    CampusEvent(
      id: 'ev3',
      title: 'Intramurals Opening Ceremony',
      host: 'Office of Student Affairs',
      start: at(5, 8),
      end: at(5, 11),
      venue: 'Main Grounds',
      description: 'Sample description. The parade of teams and the opening '
          'of the intramurals week.',
    ),
    // Registration already closed (deadline passed).
    CampusEvent(
      id: 'ev4',
      title: 'Society Coding Challenge',
      host: _css,
      hostLogo: _cssLogo,
      start: at(9, 13),
      end: at(9, 17),
      venue: 'Saint Theodore Hall · Lab 2',
      coverAsset: _cssCover,
      audience: _css,
      deadline: at(-1, 17),
      capacity: 40,
      description: 'Sample description. Teams of three solve problems in four hours.',
    ),
    // Full: every spot is taken.
    CampusEvent(
      id: 'ev5',
      title: 'Blood Donation Drive',
      host: 'Office of Student Affairs',
      start: at(12, 9),
      end: at(12, 15),
      venue: 'Library Commons',
      capacity: 60,
      description: 'Sample description. Donors must be 18 or older.',
    ),
    // Not for the mock student: he isn't a Dance Company member.
    CampusEvent(
      id: 'ev6',
      title: 'Dance Company Showcase',
      host: 'Dance Company',
      start: at(4, 18),
      end: at(4, 20),
      venue: 'Main Auditorium',
      audience: 'Dance Company',
    ),
    // A draft: only its managers see it.
    CampusEvent(
      id: 'ev7',
      title: 'Intro to Flutter Workshop',
      host: _dcs,
      start: at(16, 13),
      end: at(16, 16),
      venue: 'Saint Theodore Hall · Lab 1',
      status: EventStatus.draft,
      audience: _dcs,
      managerIds: {mockTeacher.id},
      capacity: 30,
      description: 'Sample description. Build a first app with Flutter.',
    ),
    // Past events.
    CampusEvent(
      id: 'ev8',
      title: 'Campus Cleanup Day',
      host: 'Office of Student Affairs',
      start: at(-6, 7),
      end: at(-6, 11),
      venue: 'Main Grounds',
      description: 'Sample description.',
    ),
    CampusEvent(
      id: 'ev9',
      title: 'CS Week Opening Talk',
      host: _dcs,
      start: at(-12, 13),
      end: at(-12, 15),
      venue: "Saint Mary's Conference Center",
      audience: _dcs,
      managerIds: {mockTeacher.id},
      description: 'Sample description.',
    ),
  ];
}

/// Registrations by people not in the mock rosters, so counts look lived-in.
/// Events the mock teacher manages have none: every registration on them is
/// a listed roster student.
const mockOtherRegistrations = {
  'ev1': 87, 'ev3': 240, 'ev4': 31, 'ev5': 60, 'ev6': 40, 'ev8': 52,
};

/// Registrations at start: event id → student ids. The mock student is
/// registered for the opening ceremony and a past cleanup day.
Map<String, Set<String>> mockRegistrations() => {
      'ev3': {mockStudent.id},
      'ev8': {mockStudent.id},
      'ev2': {'stu-BSCS3A1', 'stu-BSCS3A2', 'stu-BSCS3A3', 'stu-BSCS3A4', 'stu-BSCS3A5'},
      'ev9': {'stu-BSCS3A6', 'stu-BSCS3A7', 'stu-BSCS3B1'},
    };

/// Cover photos a teacher can pick in the event form (bundled assets).
const mockEventCovers = [
  _cssCover,
  'assets/images/events/css_commitevent.jpg',
  'assets/images/events/css_startupevent.jpg',
  'assets/images/events/css_unpackingevent.jpg',
];

const mockOrganizations = [
  Organization(id: 'org1', name: _css, logoAsset: _cssLogo, memberCount: 248),
  Organization(id: 'org2', name: 'SMCL Chorale', memberCount: 64),
  Organization(id: 'org3', name: 'Dance Company', memberCount: 52),
];

/// Active clearance period per user id; missing means no active period.
ClearanceSummary? mockClearanceFor(String userId, DateTime now) =>
    userId == mockStudent.id
        ? ClearanceSummary(
            periodName: '1st Semester Clearance',
            deadline: DateTime(now.year, now.month, now.day + 38),
            cleared: 3,
            total: 6,
            needsCorrection: 1, // the Library item on Home's Pending Tasks
          )
        : null;

/// Clearance office per staff user id. The mock teacher has none.
const mockClearanceOffices = <String, ClearanceOffice>{};
