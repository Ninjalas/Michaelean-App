import '../mock/mock_users.dart';
import '../models/user_profile.dart';
import 'campus_service.dart';

/// Where user profiles come from. Screens talk to this, not to mock data,
/// so a real implementation (Microsoft 365 + school records) can replace
/// MockUserService later without changing screens.
abstract class UserService {
  Future<UserProfile> loadPreviewUser(UserRole role);
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
}
