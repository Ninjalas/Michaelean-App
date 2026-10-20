import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which one-time hints were already shown, on this device
/// (browser storage on the web). Not tied to the previewed user.
class HintStore {
  static const quickQr = 'hint.quickQr';

  /// True the first time it's asked for [key]; false after that, also after
  /// the app is closed and reopened.
  static Future<bool> showOnce(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(key) ?? false) return false;
      await prefs.setBool(key, true);
      return true;
    } catch (_) {
      return false; // storage unavailable: skip the hint rather than repeat it forever
    }
  }
}
