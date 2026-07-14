package com.example.winatraai

import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import androidx.core.app.NotificationCompat
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context

class FloatingNotificationService : Service() {

    private lateinit var windowManager: WindowManager
    private lateinit var floatingView: View
    private val params: WindowManager.LayoutParams by lazy {
        WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            y = 100
        }
    }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        createNotificationChannel()
        startForeground(1, NotificationCompat.Builder(this, "floating_channel")
            .setContentTitle("Winatra AI")
            .setContentText("Mode aktif")
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .build())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.let {
            val mode = it.getStringExtra("mode") ?: "daily"
            val prompt = it.getStringExtra("prompt") ?: ""
            showFloatingNotification(mode, prompt)
        }
        return START_STICKY
    }

    private fun showFloatingNotification(mode: String, prompt: String) {
        if (::floatingView.isInitialized) {
            windowManager.removeView(floatingView)
        }

        floatingView = LayoutInflater.from(this).inflate(R.layout.floating_notification, null)
        
        val titleView = floatingView.findViewById<TextView>(R.id.tvTitle)
        val bodyView = floatingView.findViewById<TextView>(R.id.tvBody)
        val closeBtn = floatingView.findViewById<View>(R.id.btnClose)

        titleView.text = when (mode) {
            "daily" -> "📌 Winatra Daily"
            "exam" -> "📝 Mode Ujian"
            else -> "💡 Winatra AI"
        }
        bodyView.text = if (prompt.isNotEmpty()) prompt else "Ketik pertanyaanmu..."

        closeBtn.setOnClickListener {
            windowManager.removeView(floatingView)
            stopSelf()
        }

        floatingView.setOnClickListener {
            // TODO: Buka floating chat / detail
        }

        windowManager.addView(floatingView, params)
    }

    override fun onDestroy() {
        super.onDestroy()
        if (::floatingView.isInitialized) {
            windowManager.removeView(floatingView)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "floating_channel",
                "Winatra Floating Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }
}