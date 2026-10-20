import 'package:flutter/widgets.dart';

import '../models/user_profile.dart';

/// Holds who is currently being previewed. This is a development preview,
/// not sign-in and not a security mechanism.
class Session extends ChangeNotifier {
  UserProfile? _user;

  UserProfile? get user => _user;

  void startPreview(UserProfile user) {
    _user = user;
    notifyListeners();
  }

  void endPreview() {
    _user = null;
    notifyListeners();
  }
}

/// Makes the Session available to any screen: `SessionScope.of(context)`.
/// Screens that read it rebuild when the previewed user changes.
class SessionScope extends InheritedNotifier<Session> {
  const SessionScope({super.key, required Session session, required super.child})
      : super(notifier: session);

  static Session of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessionScope>()!.notifier!;
}
