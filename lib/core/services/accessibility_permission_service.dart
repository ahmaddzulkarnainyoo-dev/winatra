import 'package:flutter/services.dart';

class AccessibilityPermissionService {
  static const MethodChannel _channel = MethodChannel('com.winatra.ai/accessibility');

  /// Opens Android Accessibility Settings screen
  static Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod<void>('openAccessibilitySettings');
  }
}