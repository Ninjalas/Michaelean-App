import 'package:flutter/widgets.dart';

import '../models/user_profile.dart';

/// Holds who is currently being previewed. This is a development preview,
/// not sign-in and not a security mechanism.
class Session extends ChangeNotifier {
  UserProfile? _user;

  UserProfile? get user => _user;

  /// Goes up whenever shared data changes (e.g. attendance finalized), so
  /// screens know to reload. See [dataKey].
  int _revision = 0;

  /// Screens reload when this changes: a different user, or newer data.
  String? get dataKey => _user == null ? null : '${_user!.id}#$_revision';

  /// Tells every screen that shared data changed and should be reloaded.
  void refresh() {
    _revision++;
    notifyListeners();
  }

  void startPreview(UserProfile user) {
    _user = user;
    notifyListeners();
  }

  /// Replaces the previewed profile, e.g. after Edit Profile. Changes stay
  /// in this preview; nothing is sent anywhere.
  void update(UserProfile user) {
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
