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

/// Organizations. Officers, meetings, and descriptions are invented sample
/// data. Kinds and departments are mock assumptions, not official records.
const mockOrganizations = [
  Organization(
    id: 'org1',
    name: _css,
    logoAsset: _cssLogo,
    coverAsset: _cssCover,
    memberCount: 248,
    kind: OrgKind.society,
    department: _dcs,
    about: 'Sample description. The student society of the Department of '
        'Computer Studies: seminars, coding challenges, and study groups for '
        'anyone into computing.',
    meetings: [
      OrgMeeting(
          title: 'General assembly',
          when: 'First Friday of the month · 3:00 PM',
          place: 'Milagros Limaco Hall'),
      OrgMeeting(
          title: 'Study group',
          when: 'Every Wednesday · 4:30 PM',
          place: 'Saint Theodore Hall · Lab 2'),
    ],
    officers: [
      OrgOfficer(name: 'Andrea Bautista', position: 'President'),
      OrgOfficer(name: 'Carlo Mendoza', position: 'Vice President'),
      OrgOfficer(name: 'Erika Lim', position: 'Secretary'),
      OrgOfficer(name: 'Mark Villanueva', position: 'Adviser',
          photoAsset: 'assets/images/profiles/Sir_Georgio.png'),
    ],
  ),
  Organization(
    id: 'org2',
    name: 'SMCL Chorale',
    memberCount: 64,
    about: 'Sample description. The school choir sings at Masses, '
        'ceremonies, and the yearly concert. Auditions every semester.',
    meetings: [
      OrgMeeting(title: 'Rehearsal', when: 'Every Tuesday and Thursday · 4:00 PM',
          place: 'Music Room'),
    ],
    officers: [
      OrgOfficer(name: 'Bea Villareal', position: 'President'),
      OrgOfficer(name: 'Hans Navarro', position: 'Section leader'),
    ],
  ),
  Organization(
    id: 'org3',
    name: 'Dance Company',
    memberCount: 52,
    about: 'Sample description. Contemporary and folk dance, performing at '
        'school events and competitions.',
    meetings: [
      OrgMeeting(title: 'Practice', when: 'Every Monday and Wednesday · 5:00 PM',
          place: 'Main Auditorium'),
    ],
    officers: [
      OrgOfficer(name: 'Gabrielle Ocampo', position: 'Captain'),
    ],
  ),
  Organization(
    id: 'org4',
    name: 'Campus Ministry Volunteers',
    memberCount: 87,
    about: 'Sample description. Volunteers who help with Masses, outreach, '
        'and retreats.',
    meetings: [
      OrgMeeting(title: 'Volunteer meeting', when: 'Every other Saturday · 9:00 AM',
          place: 'Chapel Hall'),
    ],
  ),
  // Another department's society: never listed as a school-wide club.
  Organization(
    id: 'org5',
    name: 'Nursing Students Association',
    memberCount: 310,
    kind: OrgKind.society,
    department: 'Department of Nursing',
    about: 'Sample description.',
  ),
];

/// MOCK clearance requirements for the active period. Offices, wording, and
/// which requirements apply are invented sample data, not school policy.
const mockClearanceItems = [
  ClearanceItem(
    id: 'lib',
    office: 'Library',
    title: 'Book returns and fines',
    instructions: 'Return borrowed books and upload a photo of your fine receipt, if any.',
    status: ClearanceStatus.notStarted,
    evidenceRequired: true,
  ),
  ClearanceItem(
    id: 'acc',
    office: 'Accounting',
    title: 'Balance settlement',
    instructions: 'Settle your remaining balance at the cashier.',
    status: ClearanceStatus.notStarted,
  ),
  ClearanceItem(
    id: 'reg',
    office: "Registrar's Office",
    title: 'Records update',
    instructions: 'Check that your personal records are complete.',
    status: ClearanceStatus.notStarted,
  ),
  ClearanceItem(
    id: 'osa',
    office: 'Office of Student Affairs',
    title: 'ID validation',
    instructions: 'Have your school ID validated for next semester.',
    status: ClearanceStatus.notStarted,
  ),
  ClearanceItem(
    id: 'gdc',
    office: 'Guidance Office',
    title: 'Exit survey',
    instructions: 'Answer the short semester exit survey at the Guidance Office.',
    status: ClearanceStatus.notStarted,
  ),
  ClearanceItem(
    id: 'dcs-lab',
    office: _dcs,
    title: 'Laboratory equipment return',
    instructions: 'Return borrowed lab equipment to the laboratory custodian.',
    status: ClearanceStatus.notStarted,
  ),
  ClearanceItem(
    id: 'dcs-adviser',
    office: _dcs,
    title: 'Adviser sign-off',
    instructions: 'Ask your class adviser to confirm your semester requirements.',
    status: ClearanceStatus.notStarted,
  ),
  ClearanceItem(
    id: 'pub',
    office: 'Student Publication',
    title: 'Staff writer clearance',
    instructions: 'Only for members of the student publication staff.',
    status: ClearanceStatus.notStarted,
  ),
];

/// Starting statuses: student id → requirement id → (status, reason).
/// Anything missing is Not started.
Map<String, Map<String, (ClearanceStatus, String?)>> mockClearanceStatuses() => {
      mockStudent.id: {
        'lib': (
          ClearanceStatus.needsCorrection,
          'Receipt photo is unreadable. Resubmit a clearer copy.'
        ),
        'acc': (ClearanceStatus.cleared, null),
        'reg': (ClearanceStatus.cleared, null),
        'osa': (ClearanceStatus.cleared, null),
        'gdc': (ClearanceStatus.actionRequired, null),
        'dcs-lab': (ClearanceStatus.inReview, null),
        'pub': (ClearanceStatus.notApplicable, null),
      },
      'stu-BSCS3A3': {'dcs-lab': (ClearanceStatus.inReview, null)},
      'stu-BSCS3A7': {'dcs-lab': (ClearanceStatus.cleared, null)},
      'stu-BSCS3B2': {
        'dcs-lab': (ClearanceStatus.inReview, null),
        'dcs-adviser': (ClearanceStatus.inReview, null),
      },
    };

/// The active clearance period; null outside one. Students only.
({String name, DateTime deadline})? mockClearancePeriod(DateTime now) => (
      name: '1st Semester Clearance',
      deadline: DateTime(now.year, now.month, now.day + 38),
    );

/// Finished clearances per student.
final mockPastClearances = {
  mockStudent.id: [
    PastClearance(name: '2nd Semester Clearance', completedOn: DateTime(2026, 5, 20)),
    PastClearance(name: '1st Semester Clearance', completedOn: DateTime(2025, 12, 12)),
  ],
};

/// Clearance office per staff user id. Mock assumption: Mark processes the
/// Department of Computer Studies requirements.
final mockClearanceOffices = <String, String>{mockTeacher.id: _dcs};
