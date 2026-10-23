// MOCK DATA — for the frontend prototype only.
// These are invented people, not official Saint Michael's College of Laguna
// records. Affiliations below are sample assumptions, not real mappings.

import '../models/event_record.dart';
import '../models/user_profile.dart';

const mockStudent = UserProfile(
  id: 'mock-student-1',
  role: UserRole.student,
  firstName: 'Nicolas',
  lastName: 'Santos',
  designation: 'BS Computer Science · 3rd Year',
  maskedId: '2023-****-21',
  email: 'nicolas.santos@smcl.example',
  qrToken: 'MOCK-7F3K9Q',
  photoAsset: 'assets/images/profiles/nicolas.jpg',
  about: 'Sample bio. Into web development and campus tech events.',
  tags: [
    IdentityTag("Saint Michael's College of Laguna", TagKind.institution),
    IdentityTag('SBMIT', TagKind.school),
    IdentityTag('Department of Computer Studies', TagKind.department),
    // Confirmed member (mock assumption). Society membership is not assumed
    // automatic — see CLAUDE.md open decision 2.
    IdentityTag('Computer Science Society', TagKind.organization),
    // Invented school-wide club, confirmed member (mock assumption).
    IdentityTag('SMCL Chorale', TagKind.organization),
  ],
);

const mockTeacherId = 'mock-teacher-1';

const mockTeacher = UserProfile(
  id: mockTeacherId,
  role: UserRole.teacher,
  firstName: 'Mark',
  lastName: 'Villanueva',
  designation: 'Faculty · Department of Computer Studies',
  maskedId: '2015-****-93',
  email: 'mark.villanueva@smcl.example',
  qrToken: 'MOCK-2M8XW4',
  photoAsset: 'assets/images/profiles/Sir_Georgio.png',
  tags: [
    IdentityTag("Saint Michael's College of Laguna", TagKind.institution),
    IdentityTag('SBMIT', TagKind.school),
    IdentityTag('Department of Computer Studies', TagKind.department),
  ],
  // Assigned classes only: whether teachers can edit other classes is an
  // open decision (CLAUDE.md, open decision 1). Clearance: mock assumption,
  // he processes the department's requirements (see mockClearanceOffices).
  permissions: {
    Permission.manageAssignedClasses,
    Permission.manageEvents,
    Permission.processClearance,
    // Mock assumption (decided 2026-10-23): he may post to the campus feed.
    Permission.postToCampusFeed,
  },
);

/// Recorded event participation per user at the start of the preview. Roles
/// come from the event record. Each record links to a past event in
/// mock_campus.dart.
final mockEventHistory = <String, List<EventRecord>>{
  mockStudent.id: [
    EventRecord(
      id: 'h1',
      eventId: 'past-git',
      eventName: 'Commit. Push. Collaborate. Git seminar',
      date: DateTime(2026, 1, 30),
      imageAsset: 'assets/images/events/css_commitevent.jpg',
      status: ParticipationStatus.attended,
      role: EventRole.participant,
    ),
    EventRecord(
      id: 'h2',
      eventId: 'past-startup',
      eventName: 'Start-up pitching talk',
      date: DateTime(2025, 11, 14),
      imageAsset: 'assets/images/events/css_startupevent.jpg',
      status: ParticipationStatus.participated,
      role: EventRole.volunteer,
    ),
    EventRecord(
      id: 'h3',
      eventId: 'past-iris',
      eventName: 'Machine learning with the Iris dataset',
      date: DateTime(2025, 9, 26),
      imageAsset: 'assets/images/events/css_unpackingevent.jpg',
      status: ParticipationStatus.attended,
      role: EventRole.participant,
    ),
  ],
  mockTeacher.id: [
    EventRecord(
      id: 'h4',
      eventId: 'past-git',
      eventName: 'Commit. Push. Collaborate. Git seminar',
      date: DateTime(2026, 1, 30),
      imageAsset: 'assets/images/events/css_commitevent.jpg',
      status: ParticipationStatus.participated,
      role: EventRole.organizer,
    ),
    EventRecord(
      id: 'h5',
      eventId: 'past-webdev',
      eventName: 'Web development bootcamp',
      date: DateTime(2025, 8, 22),
      status: ParticipationStatus.participated,
      role: EventRole.host, // recorded as host on the event, not inferred
    ),
  ],
};
