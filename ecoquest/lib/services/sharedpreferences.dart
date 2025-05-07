import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static const String _audioKey = 'audioEnabled';
  static const String _notificationKey = 'notificationEnabled';
  static const String _userSignedInKey = 'userSignedIn';
  static const String _userIDKey = 'userID';
  static const String _userNameKey = 'userName';
  static const String _profilePicKey = 'profilePic';

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

  /// ✅ Save user ID
  static Future<void> setUserID(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIDKey, uid);
  }

  /// ✅ Get user ID
  static Future<String?> getUserID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIDKey);
  }

  /// ✅ Save user name
  static Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  /// ✅ Get user name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  /// ✅ Save profile picture URL
  static Future<void> setUserProfilePic(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profilePicKey, url);
  }

  /// ✅ Get profile picture URL
  static Future<String?> getUserProfilePic() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profilePicKey);
  }

  /// ✅ Clear only user-related preferences (logout)
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userSignedInKey);
    await prefs.remove(_userIDKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_profilePicKey);
  }
}
