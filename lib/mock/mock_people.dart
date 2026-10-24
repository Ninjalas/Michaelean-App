// MOCK DATA: sample connections, privacy settings, and activity for the
// Connect feature (spec §10.1). The people are the invented students from
// the sample class lists (mock_classes.dart); nothing here is a real record.

import '../models/event_record.dart';
import '../models/people.dart';
import '../models/user_profile.dart';
import 'mock_users.dart';

/// The tags every sample student starts with (all are in BS Computer
/// Science); club and officer tags are added from the member lists.
const mockSampleStudentTags = [
  IdentityTag("Saint Michael's College of Laguna", TagKind.institution),
  IdentityTag('SBMIT', TagKind.school),
  IdentityTag('Department of Computer Studies', TagKind.department),
];

const _nicolas = 'mock-student-1';
const _andrea = 'stu-BSCS3A1';
const _carlo = 'stu-BSCS3A2';
const _bea = 'stu-BSCS3A3';
const _diego = 'stu-BSCS3A4';
const _erika = 'stu-BSCS3A5';
const _isabel = 'stu-BSCS3A9';
const _joshua = 'stu-BSCS3A10';
const _aira = 'stu-BSCS2A1';
const _ben = 'stu-BSCS2A2';
const _alyssa = 'stu-BSCS3B1';
const _celine = 'stu-BSCS3B3';

/// Connections at the start of the preview (each pair connected both ways).
/// Nicolas has four; the others make mutual connections to show.
const mockConnections = [
  (_nicolas, _andrea),
  (_nicolas, _carlo),
  (_nicolas, _erika),
  (_nicolas, _diego),
  (_andrea, _carlo),
  (_andrea, _erika),
  (_andrea, _bea),
  (_carlo, _bea),
  (_bea, _aira),
  (_aira, _ben),
  (_diego, _joshua),
  (_erika, _isabel),
  (_alyssa, _celine),
];

/// Requests waiting at the start: (from, to, hours ago). Nicolas has two to
/// answer and one he sent.
const mockConnectRequests = [
  (_bea, _nicolas, 5),
  (_aira, _nicolas, 30),
  (_nicolas, _alyssa, 20),
];

/// Privacy settings that differ from the default (Connections for all), so
/// every case can be tried in the preview.
const mockPrivacy = {
  _andrea: PrivacySettings(
      upcomingEvents: PrivacyLevel.public,
      eventHistory: PrivacyLevel.public,
      connections: PrivacyLevel.public),
  _erika: PrivacySettings(upcomingEvents: PrivacyLevel.onlyMe),
  _diego: PrivacySettings(eventHistory: PrivacyLevel.onlyMe, connections: PrivacyLevel.public),
  _bea: PrivacySettings(upcomingEvents: PrivacyLevel.public),
  _alyssa: PrivacySettings(upcomingEvents: PrivacyLevel.public, eventHistory: PrivacyLevel.public),
  _aira: PrivacySettings(connections: PrivacyLevel.onlyMe),
};

/// Sample About text for a few students.
const mockPeopleAbout = {
  _andrea: 'Sample bio. CSS president. Into UI design and hackathons.',
  _carlo: 'Sample bio. Backend and databases; ask me about SQL.',
  _bea: 'Sample bio. Chorale and coding, in that order.',
  _alyssa: 'Sample bio. Robotics, 3D printing, and too much coffee.',
};

/// Sample registrations for upcoming events: event id → student ids. The
/// event's anonymous count (mockOtherRegistrations) was lowered by the same
/// number, so each event's total is unchanged.
const mockPeopleRegistrations = {
  'ev1': {_andrea, _carlo, _erika, 'stu-BSCS3A6'},
  'ev3': {_bea, _aira, _alyssa, _carlo, _diego},
  'ev5': {_andrea, _celine, _ben},
};

/// Sample attendance records for other students (their Event History).
final mockPeopleHistory = <String, List<EventRecord>>{
  _andrea: [
    _record('ah1', 'past-git', EventRole.organizer),
    _record('ah2', 'past-startup', EventRole.participant),
  ],
  _carlo: [
    _record('ch1', 'past-git', EventRole.participant),
    _record('ch2', 'past-iris', EventRole.participant),
  ],
  _erika: [_record('eh1', 'past-git', EventRole.participant)],
  _diego: [_record('dh1', 'past-startup', EventRole.participant)],
  _bea: [_record('bh1', 'past-iris', EventRole.volunteer)],
  _alyssa: [_record('lh1', 'past-startup', EventRole.participant)],
};

/// One sample record, copying the event's name, date, and photo from the
/// mock student's record of the same event.
EventRecord _record(String id, String eventId, EventRole role) {
  final source = mockEventHistory[_nicolas]!.firstWhere((r) => r.eventId == eventId);
  return EventRecord(
    id: id,
    eventId: eventId,
    eventName: source.eventName,
    date: source.date,
    imageAsset: source.imageAsset,
    status: ParticipationStatus.attended,
    role: role,
  );
}
