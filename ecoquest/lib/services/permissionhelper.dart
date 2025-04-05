import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  /// ✅ Request Camera Permission
  static Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  /// ✅ Request Location Permission
  static Future<bool> requestLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }
    return status.isGranted;
  }

  /// ✅ Request Gallery (Photos) Permission (iOS)
  static Future<bool> requestPhotosPermission() async {
    var status = await Permission.photos.status;
    if (!status.isGranted) {
      status = await Permission.photos.request();
    }
    return status.isGranted;
  }

  /// ✅ Request Storage Permission (Android)
  static Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  /// ✅ Request Notification Permission
  static Future<bool> requestNotificationPermission() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      status = await Permission.notification.request();
    }
    return status.isGranted;
  }

  /// ✅ Request All at Once (Optional)
  static Future<void> requestAllPermissions() async {
    await [
      Permission.camera,
      Permission.location,
      Permission.photos,
      Permission.storage,
      Permission.notification,
    ].request();
  }
}
