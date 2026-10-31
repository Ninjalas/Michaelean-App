enum UserRole { student, teacher }

/// What kind of identity label a tag is (spec §5). Used for styling only;
/// a tag never grants permissions by itself.
/// [role]: a duty the school assigned, e.g. "SMCL Robotics Club Adviser" or
/// "Department of Computer Studies Clearance Staff". Like every tag, a label,
/// not a permission.
enum TagKind { institution, school, department, organization, officer, role }

class IdentityTag {
  final String label;
  final TagKind kind;

  const IdentityTag(this.label, this.kind);
}

/// Actions a user is explicitly authorized to do (spec §12).
/// Kept separate from tags on purpose: identity is not permission.
enum Permission {
  manageAssignedClasses,
  manageEvents,
  processClearance,
  manageOrganizationContent,
  postToCampusFeed, // announcements, school news, campus updates from Home's + button
  holdConsultations, // consultation forms with students (decided 2026-10-30)
}

class UserProfile {
  final String id;
  final UserRole role;
  final String firstName;
  final String lastName;
  final String designation; // e.g. "BS Computer Science · 3rd Year"
  final String maskedId; // never store or show the full ID in the prototype
  final String email; // school account email (sample addresses in the prototype)
  final String qrToken; // random mock token, never personal data
  final String? photoAsset; // null → show initials
  final String? about; // optional short bio the user can edit
  final List<IdentityTag> tags;
  final Set<Permission> permissions;

  const UserProfile({
    required this.id,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.designation,
    required this.maskedId,
    required this.email,
    required this.qrToken,
    this.photoAsset,
    this.about,
    required this.tags,
    this.permissions = const {},
  });

  String get fullName => '$firstName $lastName';

  /// The same profile with new About text. About and the photo are the only
  /// things a user may edit (spec §10).
  UserProfile withAbout(String? about) => UserProfile(
        id: id,
        role: role,
        firstName: firstName,
        lastName: lastName,
        designation: designation,
        maskedId: maskedId,
        email: email,
        qrToken: qrToken,
        photoAsset: photoAsset,
        about: about,
        tags: tags,
        permissions: permissions,
      );

  /// The same profile with other identity tags, e.g. after a club adviser
  /// accepted or removed a membership in this preview.
  UserProfile withTags(List<IdentityTag> tags) => UserProfile(
        id: id,
        role: role,
        firstName: firstName,
        lastName: lastName,
        designation: designation,
        maskedId: maskedId,
        email: email,
        qrToken: qrToken,
        photoAsset: photoAsset,
        about: about,
        tags: tags,
        permissions: permissions,
      );

  bool can(Permission p) => permissions.contains(p);
}
