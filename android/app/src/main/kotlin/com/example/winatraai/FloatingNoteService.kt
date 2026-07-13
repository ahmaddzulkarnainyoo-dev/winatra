package com.winatra.ai

import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView

class FloatingNoteService : Service() {
    private lateinit var windowManager: WindowManager
    private var floatingView: android.view.View? = null

    // mode aktif: "pelajar" atau "daily" — dikirim dari Flutter lewat MethodChannel
    private var currentMode: String = "pelajar"

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        showFloatingWidget()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        currentMode = intent?.getStringExtra("mode") ?: currentMode
        updateButtonsForMode()
        return START_STICKY
    }

    private fun showFloatingWidget() {
        floatingView = LayoutInflater.from(this).inflate(R.layout.floating_note, null)
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.TOP or Gravity.END
        windowManager.addView(floatingView, params)
        updateButtonsForMode()
    }

    private fun updateButtonsForMode() {
        val btnPrimary = floatingView?.findViewById<Button>(R.id.btnPrimary)
        val btnSecondary = floatingView?.findViewById<Button>(R.id.btnSecondary)
        if (currentMode == "pelajar") {
            btnPrimary?.text = "Jawab"
            btnSecondary?.visibility = android.view.View.GONE
        } else {
            btnPrimary?.text = "Nanya"
            btnSecondary?.text = "Ini Apa?"
            btnSecondary?.visibility = android.view.View.VISIBLE
        }
        // TODO: onClick btnPrimary -> trigger MethodChannel ke Flutter -> panggil DeepSeek API
    }

    override fun onDestroy() {
        super.onDestroy()
        floatingView?.let { windowManager.removeView(it) }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}