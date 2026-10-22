import 'package:shared_preferences/shared_preferences.dart';

import '../models/feed.dart';

/// Which notification types are switched off, saved on this device (browser
/// storage on the web). Not tied to the previewed user. Urgent notifications
/// ignore these switches.
class NotificationPrefs {
  static String _key(NotificationKind k) => 'notify.${k.name}';

  /// Storage can be slow or blocked; never let it hold up the screen.
  static Future<SharedPreferences> _prefs() =>
      SharedPreferences.getInstance().timeout(const Duration(seconds: 2));

  /// The types switched off; none when storage is unavailable.
  static Future<Set<NotificationKind>> muted() async {
    try {
      final prefs = await _prefs();
      return {
        for (final k in NotificationKind.values)
          if (prefs.getBool(_key(k)) == false) k,
      };
    } catch (_) {
      return {};
    }
  }

  /// Saves one switch. Returns false when it couldn't be saved.
  static Future<bool> set(NotificationKind kind, bool on) async {
    try {
      final prefs = await _prefs();
      return await prefs.setBool(_key(kind), on);
    } catch (_) {
      return false;
    }
  }
}
