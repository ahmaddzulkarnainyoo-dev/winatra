import 'package:permission_handler/permission_handler.dart';

class NotificationPermissionService {
  /// Request notification permission. Returns true if granted.
  static Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Check if notification permission is already granted.
  static Future<bool> hasPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }
}