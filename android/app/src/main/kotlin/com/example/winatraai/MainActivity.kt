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
    private val FLOATING_CHANNEL = "com.winatra.ai/floating_service"

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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FLOATING_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startFloating" -> {
                        val mode = call.argument<String>("mode") ?: "pelajar"
                        val intent = Intent(this, FloatingNotesService::class.java)
                        intent.putExtra("mode", mode)
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
    }
}