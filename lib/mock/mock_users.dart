// MOCK DATA — for the frontend prototype only.
// These are invented people, not official Saint Michael's College of Laguna
// records. Affiliations below are sample assumptions, not real mappings.

import '../models/user_profile.dart';

const mockStudent = UserProfile(
  id: 'mock-student-1',
  role: UserRole.student,
  firstName: 'Andrea',
  lastName: 'Reyes',
  designation: 'BS Computer Science · 3rd Year',
  maskedId: '••••-••-4821',
  qrToken: 'MOCK-7F3K9Q',
  tags: [
    IdentityTag("Saint Michael's College of Laguna", TagKind.institution),
    IdentityTag('SBMIT', TagKind.school),
    IdentityTag('Department of Computer Studies', TagKind.department),
    IdentityTag('Dance Company', TagKind.organization),
    IdentityTag('Dance Company Officer', TagKind.officer),
  ],
  permissions: {Permission.manageOrganizationContent},
);

const mockTeacher = UserProfile(
  id: 'mock-teacher-1',
  role: UserRole.teacher,
  firstName: 'Mark',
  lastName: 'Santos',
  designation: 'Faculty · Department of Computer Studies',
  maskedId: '••••-1093',
  qrToken: 'MOCK-2M8XW4',
  tags: [
    IdentityTag("Saint Michael's College of Laguna", TagKind.institution),
    IdentityTag('SBMIT', TagKind.school),
    IdentityTag('Department of Computer Studies', TagKind.department),
  ],
  // Assigned classes only: whether teachers can edit other classes is an
  // open decision (CLAUDE.md, open decision 1).
  permissions: {Permission.manageAssignedClasses, Permission.manageEvents},
);
