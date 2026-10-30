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
      postedAt: now.subtract(const Duration(days: 1)),
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
      postedAt: now.subtract(const Duration(days: 3)),
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
      postedAt: now.subtract(const Duration(hours: 5)),
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
      postedAt: now.subtract(const Duration(days: 10)), // too old for the bell
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
      postedAt: now.subtract(const Duration(days: 2)),
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
      postedAt: now.subtract(const Duration(days: 2)),
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
    // Earlier events behind the sample Event History (mock_users.dart).
    // Fixed dates: they happened before this preview.
    CampusEvent(
      id: 'past-git',
      title: 'Commit. Push. Collaborate. Git seminar',
      host: _css,
      hostLogo: _cssLogo,
      start: DateTime(2026, 1, 30, 13),
      end: DateTime(2026, 1, 30, 16),
      venue: 'Saint Theodore Hall · Lab 2',
      coverAsset: 'assets/images/events/css_commitevent.jpg',
      audience: _css,
      description: 'Sample description. A hands-on seminar on committing, pushing, and '
          'working together on a shared repository.',
    ),
    CampusEvent(
      id: 'past-startup',
      title: 'Start-up pitching talk',
      host: _css,
      hostLogo: _cssLogo,
      start: DateTime(2025, 11, 14, 14),
      end: DateTime(2025, 11, 14, 17),
      venue: 'Milagros Limaco Hall',
      coverAsset: 'assets/images/events/css_startupevent.jpg',
      audience: _css,
      description: 'Sample description. Student teams pitched start-up ideas to a panel.',
    ),
    CampusEvent(
      id: 'past-iris',
      title: 'Machine learning with the Iris dataset',
      host: _css,
      hostLogo: _cssLogo,
      start: DateTime(2025, 9, 26, 13),
      end: DateTime(2025, 9, 26, 16),
      venue: 'Saint Theodore Hall · Lab 1',
      coverAsset: 'assets/images/events/css_unpackingevent.jpg',
      audience: _css,
      description: 'Sample description. A first look at machine learning with a classic '
          'dataset.',
    ),
    CampusEvent(
      id: 'past-webdev',
      title: 'Web development bootcamp',
      host: _dcs,
      start: DateTime(2025, 8, 22, 9),
      end: DateTime(2025, 8, 22, 16),
      venue: 'Saint Theodore Hall · Lab 2',
      audience: _dcs,
      managerIds: {mockTeacher.id},
      description: 'Sample description. A one-day bootcamp on building websites.',
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
  // ev1, ev3, ev5: lowered by the sample people now registered by name
  // (mockPeopleRegistrations), so the totals are unchanged.
  'ev1': 83, 'ev3': 235, 'ev4': 31, 'ev5': 57, 'ev6': 40, 'ev8': 52,
  'past-git': 64, 'past-startup': 118, 'past-iris': 45,
};

/// Events whose attendance was already finalized before this preview (their
/// records are the sample Event History).
const mockFinalizedEvents = {'past-git', 'past-startup', 'past-iris', 'past-webdev'};

/// Registrations at start: event id → student ids. The mock student is
/// registered for the opening ceremony and a past cleanup day.
Map<String, Set<String>> mockRegistrations() => {
      'ev3': {mockStudent.id},
      'ev8': {mockStudent.id},
      'ev2': {'stu-BSCS3A1', 'stu-BSCS3A2', 'stu-BSCS3A3', 'stu-BSCS3A4', 'stu-BSCS3A5'},
      'ev9': {'stu-BSCS3A6', 'stu-BSCS3A7', 'stu-BSCS3B1'},
    };

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
    // Officers come from its member list (mockClubMembers) and advisers.
    adviserIds: [mockTeacherId],
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
  Organization(
    id: 'org6',
    name: 'SMCL Robotics Club',
    memberCount: 6,
    about: 'Sample description. Students who build and program robots, and '
        'join inter-school robotics challenges.',
    meetings: [
      OrgMeeting(title: 'Build session', when: 'Every Thursday · 4:00 PM',
          place: 'Saint Theodore Hall · Lab 2'),
    ],
    adviserIds: [mockTeacherId],
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

/// MOCK club member lists: student id → officer position (null for a plain
/// member). Names come from the sample class rosters. Mark advises CSS and
/// the Robotics Club (mock assumption, decided 2026-10-23). The other
/// school-wide clubs got lists so a teacher can invite all their members
/// (decided 2026-10-30); their member counts follow the lists. The Nursing
/// Students Association has no sample students, so it keeps its tag rule.
const mockClubMembers = <String, Map<String, String?>>{
  'org1': {
    'mock-student-1': null, // Nicolas
    'stu-BSCS3A1': 'President', // Andrea Bautista
    'stu-BSCS3A2': 'Vice President', // Carlo Mendoza
    'stu-BSCS3A5': 'Secretary', // Erika Lim
    'stu-BSCS3A6': null,
    'stu-BSCS3A9': null,
    'stu-BSCS2A1': null,
    'stu-BSCS2A2': null,
    'stu-BSCS3B1': null,
  },
  'org2': {
    'mock-student-1': null, // Nicolas
    'stu-BSCS3A3': 'President', // Bea Villareal
    'stu-BSCS3A8': 'Section leader', // Hans Navarro
    'stu-BSCS2A3': null,
    'stu-BSCS2A8': null,
    'stu-BSCS3B5': null,
    'stu-BSCS3B7': null,
  },
  'org3': {
    'stu-BSCS3A7': 'Captain', // Gabrielle Ocampo
    'stu-BSCS3A11': null,
    'stu-BSCS2A5': null,
    'stu-BSCS2A6': null,
    'stu-BSCS2A9': null,
    'stu-BSCS3B4': null,
    'stu-BSCS3B9': null,
    'stu-BSCS3B11': null,
  },
  'org4': {
    'stu-BSCS3A6': 'President', // Francis Tan
    'stu-BSCS3A10': null,
    'stu-BSCS2A4': null,
    'stu-BSCS2A7': null,
    'stu-BSCS2A12': null,
    'stu-BSCS3B6': null,
    'stu-BSCS3B10': null,
  },
  'org6': {
    'stu-BSCS3A4': 'President', // Diego Ramos
    'stu-BSCS3A10': null,
    'stu-BSCS2A6': null,
    'stu-BSCS2A7': null,
    'stu-BSCS3B2': null,
    'stu-BSCS3B12': null,
  },
};

/// MOCK students waiting for an answer to "Request to join", oldest first.
const mockJoinRequests = <String, List<String>>{
  'org1': ['stu-BSCS3B3', 'stu-BSCS2A10'],
  'org6': ['stu-BSCS3A11', 'stu-BSCS3B4', 'stu-BSCS2A9'],
};

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

/// MOCK office contacts for Help & Support. Rooms, hours, and local numbers
/// are invented; the real directory will come from the school.
const mockSupportContacts = [
  SupportContact(
    office: "Registrar's Office",
    helpsWith: 'Personal information, IDs, records',
    place: 'Pura Limaco Hall I · Ground floor',
    hours: 'Mon–Fri, 8:00 AM – 5:00 PM',
    contact: 'Local 101 (sample)',
  ),
  SupportContact(
    office: 'Office of Student Affairs',
    helpsWith: 'Events, organizations, school IDs',
    place: 'Milagros Limaco Hall · 102',
    hours: 'Mon–Sat, 8:00 AM – 5:00 PM',
    contact: 'Local 120 (sample)',
  ),
  SupportContact(
    office: 'Guidance Office',
    helpsWith: 'Counseling, exit surveys',
    place: 'Pura Limaco Hall I · 110',
    hours: 'Mon–Fri, 8:00 AM – 5:00 PM',
    contact: 'Local 130 (sample)',
  ),
  SupportContact(
    office: 'IT Help Desk',
    helpsWith: 'Microsoft 365 account, the Michaelean app',
    place: 'Saint Theodore Hall · Lab 3',
    hours: 'Mon–Fri, 8:00 AM – 6:00 PM',
    contact: 'Local 150 (sample)',
  ),
];
