enum UserRole { student, teacher }

/// What kind of identity label a tag is (spec §5). Used for styling only;
/// a tag never grants permissions by itself.
enum TagKind { institution, school, department, organization, officer }

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
}

class UserProfile {
  final String id;
  final UserRole role;
  final String firstName;
  final String lastName;
  final String designation; // e.g. "BS Computer Science · 3rd Year"
  final String maskedId; // never store or show the full ID in the prototype
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
        qrToken: qrToken,
        photoAsset: photoAsset,
        about: about,
        tags: tags,
        permissions: permissions,
      );

  bool can(Permission p) => permissions.contains(p);
}
