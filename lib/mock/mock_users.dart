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
  maskedId: '••••-••-4821',
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
  ],
);

const mockTeacher = UserProfile(
  id: 'mock-teacher-1',
  role: UserRole.teacher,
  firstName: 'Mark',
  lastName: 'Villanueva',
  designation: 'Faculty · Department of Computer Studies',
  maskedId: '••••-1093',
  qrToken: 'MOCK-2M8XW4',
  photoAsset: 'assets/images/profiles/Sir_Georgio.png',
  tags: [
    IdentityTag("Saint Michael's College of Laguna", TagKind.institution),
    IdentityTag('SBMIT', TagKind.school),
    IdentityTag('Department of Computer Studies', TagKind.department),
  ],
  // Assigned classes only: whether teachers can edit other classes is an
  // open decision (CLAUDE.md, open decision 1).
  permissions: {Permission.manageAssignedClasses, Permission.manageEvents},
);

/// Recorded event participation per user. Roles come from the event record.
final mockEventHistory = <String, List<EventRecord>>{
  mockStudent.id: [
    EventRecord(
      id: 'h1',
      eventName: 'Commit. Push. Collaborate. Git seminar',
      date: DateTime(2026, 1, 30),
      imageAsset: 'assets/images/events/css_commitevent.jpg',
      status: ParticipationStatus.attended,
      role: EventRole.participant,
    ),
    EventRecord(
      id: 'h2',
      eventName: 'Start-up pitching talk',
      date: DateTime(2025, 11, 14),
      imageAsset: 'assets/images/events/css_startupevent.jpg',
      status: ParticipationStatus.participated,
      role: EventRole.volunteer,
    ),
    EventRecord(
      id: 'h3',
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
      eventName: 'Commit. Push. Collaborate. Git seminar',
      date: DateTime(2026, 1, 30),
      imageAsset: 'assets/images/events/css_commitevent.jpg',
      status: ParticipationStatus.participated,
      role: EventRole.organizer,
    ),
  ],
};
