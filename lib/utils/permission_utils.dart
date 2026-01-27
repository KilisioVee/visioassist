import 'package:permission_handler/permission_handler.dart';

/// Utility class for handling permissions across the app.
class PermissionUtils {
  /// Request camera permission
  /// Returns true if permission is granted
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request photos permission (gallery access)
  /// Returns true if permission is granted
  static Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  /// Check if camera permission is granted
  static Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Check if photos permission is granted
  static Future<bool> hasPhotosPermission() async {
    final status = await Permission.photos.status;
    return status.isGranted;
  }

  /// Open app settings for permission management
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
