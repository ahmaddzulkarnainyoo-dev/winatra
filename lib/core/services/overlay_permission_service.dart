import 'package:flutter/services.dart';

class OverlayPermissionService {
  static const MethodChannel _channel = MethodChannel('com.winatra.ai/overlay');

  /// Returns whether the app already has permission to draw over other apps.
  static Future<bool> hasPermission() async {
    final result = await _channel.invokeMethod<bool>('hasOverlayPermission');
    return result ?? false;
  }

  /// Opens Android Settings screen so the user can manually grant overlay permission.
  static Future<void> requestPermission() async {
    await _channel.invokeMethod<void>('requestOverlayPermission');
  }
}

