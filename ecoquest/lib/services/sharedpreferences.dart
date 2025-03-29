import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static const String _audioKey = 'audioEnabled';
  static const String _notificationKey = 'notificationEnabled';
  static const String _userSignedInKey = 'userSignedIn';

  /// ✅ Save audio setting
  static Future<void> setAudioEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_audioKey, isEnabled);
  }

  /// ✅ Get audio setting (default: true)
  static Future<bool> getAudioEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_audioKey) ?? true;
  }

  /// ✅ Save notification setting
  static Future<void> setNotificationEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationKey, isEnabled);
  }

  /// ✅ Get notification setting (default: true)
  static Future<bool> getNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationKey) ?? true;
  }

  /// ✅ Save user signed-in status
  static Future<void> setUserSignedIn(bool isSignedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_userSignedInKey, isSignedIn);
  }

  /// ✅ Get user signed-in status (default: false)
  static Future<bool> getUserSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_userSignedInKey) ?? false;
  }
}
