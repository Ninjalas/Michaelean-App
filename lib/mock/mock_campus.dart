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
      venue: 'Milagros Limaco Hall',
      coverAsset: _cssCover,
      audience: _css,
    ),
    CampusEvent(
      id: 'ev2',
      title: 'Department Assembly',
      host: _dcs,
      start: at(3, 14),
      venue: "Saint Mary's Conference Center",
      audience: _dcs,
      managerIds: {mockTeacher.id},
    ),
    CampusEvent(
      id: 'ev3',
      title: 'Intramurals Opening Ceremony',
      host: 'Office of Student Affairs',
      start: at(5, 8),
      venue: 'Main Grounds',
    ),
    CampusEvent(
      id: 'ev4',
      title: 'Society Coding Challenge',
      host: _css,
      hostLogo: _cssLogo,
      start: at(9, 13),
      venue: 'Saint Theodore Hall · Lab 2',
      coverAsset: _cssCover,
      audience: _css,
    ),
    CampusEvent(
      id: 'ev5',
      title: 'Blood Donation Drive',
      host: 'Office of Student Affairs',
      start: at(12, 9),
      venue: 'Library Commons',
    ),
    // Not for the mock student: he isn't a Dance Company member.
    CampusEvent(
      id: 'ev6',
      title: 'Dance Company Showcase',
      host: 'Dance Company',
      start: at(4, 18),
      venue: 'Main Auditorium',
      audience: 'Dance Company',
    ),
    // A draft: only its managers see it.
    CampusEvent(
      id: 'ev7',
      title: 'Intro to Flutter Workshop',
      host: _dcs,
      start: at(16, 13),
      venue: 'Saint Theodore Hall · Lab 1',
      status: EventStatus.draft,
      audience: _dcs,
      managerIds: {mockTeacher.id},
    ),
  ];
}

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
