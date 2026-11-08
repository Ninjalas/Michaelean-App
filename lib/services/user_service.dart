import '../mock/mock_users.dart';
import '../models/user_profile.dart';
import 'campus_service.dart';

/// Where user profiles come from. Screens talk to this, not to mock data or
/// Supabase directly. [MockUserService] is the sample-data preview;
/// SupabaseUserService (supabase_user_service.dart) adds real test accounts.
abstract class UserService {
  /// A sample student or teacher for the preview. Not a sign-in.
  Future<UserProfile> loadPreviewUser(UserRole role);

  /// The account still signed in from last time, or null.
  Future<UserProfile?> restoreSignIn();

  /// Signs in to a test account. Throws [SignInException] with a message
  /// that can be shown as is.
  Future<UserProfile> signIn(String email, String password);

  Future<void> signOut();

  /// Checks [current] first, then sets [next]. Throws [SignInException].
  Future<void> changePassword(String current, String next);
}

class SignInException implements Exception {
  final String message;
  const SignInException(this.message);

  @override
  String toString() => message;
}

class MockUserService implements UserService {
  /// When given, club memberships come from its member lists, so a change a
  /// club adviser made shows when the account is loaded again.
  final CampusService? campus;

  MockUserService({this.campus});

  @override
  Future<UserProfile> loadPreviewUser(UserRole role) async {
    final user = role == UserRole.student ? mockStudent : mockTeacher;
    return campus?.withAffiliations(user) ?? user;
  }

  // The preview has no accounts.
  @override
  Future<UserProfile?> restoreSignIn() async => null;

  @override
  Future<UserProfile> signIn(String email, String password) =>
      throw const SignInException('Accounts are not available in this preview.');

  @override
  Future<void> signOut() async {}

  @override
  Future<void> changePassword(String current, String next) =>
      throw const SignInException('Accounts are not available in this preview.');
}
