package com.winatra.ai

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat

class KenapaReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val alasan = intent.getStringExtra("alasan") ?: "Alasan tidak tersedia."
        val notif = NotificationCompat.Builder(context, "winatra_answers")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("Kenapa jawabannya itu?")
            .setContentText(alasan)
            .setStyle(NotificationCompat.BigTextStyle().bigText(alasan))
            .setAutoCancel(true)
            .build()
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .notify(999, notif)
    }
}