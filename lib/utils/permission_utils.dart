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
  /// Handles both Android 13+ (READ_MEDIA_IMAGES) and earlier versions (READ_EXTERNAL_STORAGE)
  static Future<bool> requestPhotosPermission() async {
    try {
      // Try the new permission first (Android 13+)
      PermissionStatus status = await Permission.photos.request();
      
      // If it's denied, and we're on an older Android version, try storage permission
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      
      return status.isGranted;
    } catch (e) {
      print('Error requesting photos permission: $e');
      return false;
    }
  }

  /// Check if camera permission is granted
  static Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Check if photos permission is granted
  /// Checks both READ_MEDIA_IMAGES and READ_EXTERNAL_STORAGE depending on Android version
  static Future<bool> hasPhotosPermission() async {
    try {
      // Check photos permission first (Android 13+)
      PermissionStatus status = await Permission.photos.status;
      
      if (status.isGranted) {
        return true;
      }
      
      // Fall back to storage permission check (Android 12 and below)
      status = await Permission.storage.status;
      return status.isGranted;
    } catch (e) {
      print('Error checking photos permission: $e');
      return false;
    }
  }

  /// Open app settings for permission management
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}

