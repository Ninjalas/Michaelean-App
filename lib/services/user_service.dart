import '../mock/mock_users.dart';
import '../models/user_profile.dart';

/// Where user profiles come from. Screens talk to this, not to mock data,
/// so a real implementation (Microsoft 365 + school records) can replace
/// MockUserService later without changing screens.
abstract class UserService {
  Future<UserProfile> loadPreviewUser(UserRole role);
}

class MockUserService implements UserService {
  @override
  Future<UserProfile> loadPreviewUser(UserRole role) async =>
      role == UserRole.student ? mockStudent : mockTeacher;
}
