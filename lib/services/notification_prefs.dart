import 'package:shared_preferences/shared_preferences.dart';

import '../models/feed.dart';

/// Notification settings saved on this device (browser storage on the web):
/// which types are switched off (for everyone on this device; urgent
/// notifications ignore them) and which notifications each user has read.
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

  /// Whether the bell shows [n] given the switched-off types.
  static bool shows(AppNotification n, Set<NotificationKind> muted) =>
      n.urgent || !muted.contains(n.kind);

  static String _readKey(String userId) => 'notify.read.$userId';

  /// Notifications this user has read on this device; none when storage is unavailable.
  static Future<Set<String>> readIds(String userId) async {
    try {
      final prefs = await _prefs();
      return {...?prefs.getStringList(_readKey(userId))};
    } catch (_) {
      return {};
    }
  }

  /// Saves which notifications this user has read. Returns false when it couldn't be saved.
  static Future<bool> saveReadIds(String userId, Set<String> ids) async {
    try {
      final prefs = await _prefs();
      return await prefs.setStringList(_readKey(userId), ids.toList());
    } catch (_) {
      return false;
    }
  }
}
