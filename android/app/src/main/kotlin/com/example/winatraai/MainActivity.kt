package com.example.winatraai

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val OVERLAY_CHANNEL = "com.winatra.ai/overlay"
    private val ACCESSIBILITY_CHANNEL = "com.winatra.ai/accessibility"
    private val FLOATING_CHANNEL = "com.winatra.ai/floating_service"
    private val KEYBOARD_CHANNEL = "com.winatra.ai/keyboard"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasOverlayPermission" -> {
                        val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            Settings.canDrawOverlays(this)
                        } else {
                            true
                        }
                        result.success(granted)
                    }
                    "requestOverlayPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ACCESSIBILITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openAccessibilitySettings" -> {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        startActivity(intent)
                        result.success(null)
                    }
                    "isAccessibilityEnabled" -> {
                        val enabledServices = Settings.Secure.getString(
                            contentResolver,
                            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
                        ) ?: ""
                        val isEnabled = enabledServices.contains(
                            "$packageName/.WinatraAccessibilityService"
                        )
                        result.success(isEnabled)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FLOATING_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startFloating" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
                            result.error("NO_PERMISSION", "Overlay permission belum aktif", null)
                            return@setMethodCallHandler
                        }
                        val mode = call.argument<String>("mode") ?: "daily"
                        val prompt = call.argument<String>("prompt") ?: ""
                        val intent = Intent(this, FloatingNotificationService::class.java).apply {
                            putExtra("mode", mode)
                            putExtra("prompt", prompt)
                        }
                        startService(intent)
                        result.success(null)
                    }
                    "startFloatingNotes" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
                            result.error("NO_PERMISSION", "Overlay permission belum aktif", null)
                            return@setMethodCallHandler
                        }
                        val mode = call.argument<String>("mode") ?: "pelajar"
                        val floatingMode = call.argument<Boolean>("floatingMode") ?: true
                        val intent = Intent(this, FloatingNotesService::class.java)
                        intent.putExtra("mode", mode)
                        intent.putExtra("floatingMode", floatingMode)
                        startService(intent)
                        result.success(null)
                    }
                    "stopFloating" -> {
                        stopService(Intent(this, FloatingNotesService::class.java))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KEYBOARD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openKeyboardSettings" -> {
                        val intent = Intent(Settings.ACTION_INPUT_METHOD_SETTINGS)
                        startActivity(intent)
                        result.success(null)
                    }
                    "isDefaultKeyboard" -> {
                        val defaultInputMethod = Settings.Secure.getString(
                            contentResolver,
                            Settings.Secure.DEFAULT_INPUT_METHOD
                        )
                        val isDefault = defaultInputMethod?.contains("com.example.winatraai") == true
                        result.success(isDefault)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}

        