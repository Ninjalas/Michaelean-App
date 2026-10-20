import '../mock/mock_users.dart';
import '../models/event_record.dart';
import '../models/user_profile.dart';

/// Where user profiles come from. Screens talk to this, not to mock data,
/// so a real implementation (Microsoft 365 + school records) can replace
/// MockUserService later without changing screens.
abstract class UserService {
  Future<UserProfile> loadPreviewUser(UserRole role);
  Future<List<EventRecord>> loadEventHistory(UserProfile user);
}

class MockUserService implements UserService {
  @override
  Future<UserProfile> loadPreviewUser(UserRole role) async =>
      role == UserRole.student ? mockStudent : mockTeacher;

  @override
  Future<List<EventRecord>> loadEventHistory(UserProfile user) async =>
      [...?mockEventHistory[user.id]]..sort((a, b) => b.date.compareTo(a.date));
}
