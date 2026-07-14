package com.example.winatraai

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.PixelFormat
import android.os.*
import android.view.Gravity
import android.view.LayoutInflater
import android.view.WindowManager
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.RemoteViews
import android.widget.Spinner
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class FloatingNotesService : Service() {
    private lateinit var windowManager: WindowManager
    private var floatingView: android.view.View? = null
    private var currentMode: String = "pelajar"
    private var lastFullAnswer: String = "" // cache buat tombol "Kenapa?", gak perlu API call ulang
    private var selectedMapel: String = "Umum"
    private var lastRequestTime: Long = 0L
    private val minRequestInterval = 5000L // 5 detik rate-limit

    private val workerUrl = "https://winatraai.himlabnews.workers.dev"
    private val channelId = "winatra_answers"

    private val mapelList = arrayOf(
        "Umum", "Matematika SD", "Matematika SMP", "Matematika SMA", "Matematika Kuliah",
        "Fisika SD", "Fisika SMP", "Fisika SMA", "Fisika Kuliah",
        "Kimia SMA", "Kimia Kuliah",
        "Biologi SD", "Biologi SMP", "Biologi SMA", "Biologi Kuliah",
        "Bahasa Indonesia", "Bahasa Inggris",
        "Sejarah", "Geografi", "Ekonomi", "Sosiologi",
        "Agama", "PKN", "TIK", "Seni Budaya", "PJOK"
    )

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        createNotificationChannel()
        showFloatingWidget()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        currentMode = intent?.getStringExtra("mode") ?: currentMode
        updateButtonsForMode()
        return START_STICKY
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            channelId, "Jawaban Winatra", NotificationManager.IMPORTANCE_HIGH
        )
        (getSystemService(NotificationManager::class.java)).createNotificationChannel(channel)
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
        
        // Setup spinner mapel
        val spinner = floatingView?.findViewById<Spinner>(R.id.spinnerMapel)
        val adapter = ArrayAdapter(this, android.R.layout.simple_spinner_dropdown_item, mapelList)
        spinner?.adapter = adapter
        spinner?.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>?, view: android.view.View?, pos: Int, id: Long) {
                selectedMapel = mapelList[pos]
            }
            override fun onNothingSelected(parent: AdapterView<*>?) {}
        }
        
        updateButtonsForMode()
    }

    private fun updateButtonsForMode() {
        val btnPrimary = floatingView?.findViewById<Button>(R.id.btnPrimary)
        val btnSecondary = floatingView?.findViewById<Button>(R.id.btnSecondary)
        val spinner = floatingView?.findViewById<Spinner>(R.id.spinnerMapel)

        if (currentMode == "pelajar") {
            btnPrimary?.text = "Jawab"
            btnSecondary?.visibility = android.view.View.GONE
            spinner?.visibility = android.view.View.VISIBLE
            btnPrimary?.setOnClickListener { handleJawabClicked() }
        } else {
            btnPrimary?.text = "Nanya"
            btnSecondary?.text = "Ini Apa?"
            btnSecondary?.visibility = android.view.View.VISIBLE
            spinner?.visibility = android.view.View.GONE
            btnPrimary?.setOnClickListener { handleNanyaClicked() }
            btnSecondary?.setOnClickListener { handleIniApaClicked() }
        }
    }

    private fun isRateLimited(): Boolean {
        val now = System.currentTimeMillis()
        if (now - lastRequestTime < minRequestInterval) return true
        lastRequestTime = now
        return false
    }

    private fun handleNanyaClicked() {
        val prompt = getClipboardText() ?: return
        Thread {
            val result = callWorker("Pertanyaan: $prompt\n\nJawab dengan jelas dan informatif.")
            showAnswerNotification(result, showKenapaButton = false)
        }.start()
    }

    private fun handleIniApaClicked() {
        val content = getClipboardText() ?: return
        Thread {
            val result = callWorker("Jelaskan konten berikut dengan singkat dan padat:\n\n$content")
            showAnswerNotification(result, showKenapaButton = false)
        }.start()
    }

    private fun handleJawabClicked() {
        if (isRateLimited()) {
            showAnswerNotification("⏱ Harap tunggu ${minRequestInterval/1000} detik sebelum request berikutnya.", showKenapaButton = false)
            return
        }
        val soal = getClipboardText() ?: return
        val isPilihanGanda = soal.contains(Regex("[A-D]\\."))

        val prompt = if (isPilihanGanda) {
            "Soal: $soal\n\nJawab HANYA huruf A/B/C/D di baris pertama. " +
            "Baris kedua, kasih alasan singkat kenapa itu jawabannya."
        } else {
            "Soal essay: $soal\n\nJawab lengkap dan jelas."
        }

        Thread {
            val result = callWorker(prompt)
            val lines = result.split("\n", limit = 2)

            if (isPilihanGanda) {
                lastFullAnswer = if (lines.size > 1) lines[1] else ""
                showAnswerNotification(lines[0].trim(), showKenapaButton = true)
            } else {
                // Auto-copy essay ke clipboard biar tinggal paste di mana aja
                val clipboard = getSystemService(CLIPBOARD_SERVICE) as android.content.ClipboardManager
                clipboard.setPrimaryClip(android.content.ClipData.newPlainText("jawaban_winatra", result))
                showAnswerNotification(
                    "✅ Sudah di-copy ke clipboard\n\n$result",
                    showKenapaButton = false
                )
            }
        }.start()
    }

    private fun callWorker(prompt: String, seriousMode: Boolean = false): String {
        return try {
            val conn = URL(workerUrl).openConnection() as HttpURLConnection
            conn.requestMethod = "POST"
            conn.setRequestProperty("Content-Type", "application/json")
            conn.doOutput = true

            val body = JSONObject().apply {
                put("prompt", prompt)
                put("seriousMode", seriousMode)
            }
            conn.outputStream.write(body.toString().toByteArray())

            val response = conn.inputStream.bufferedReader().readText()
            JSONObject(response).getString("answer")
        } catch (e: Exception) {
            "Gagal ambil jawaban: ${e.message}"
        }
    }

    private fun getClipboardText(): String? {
        val clipboard = getSystemService(CLIPBOARD_SERVICE) as android.content.ClipboardManager
        return clipboard.primaryClip?.getItemAt(0)?.text?.toString()
    }

    private fun showAnswerNotification(text: String, showKenapaButton: Boolean) {
        // RemoteViews untuk collapsed (small) dan expanded (big)
        val smallRv = RemoteViews(packageName, R.layout.notification_answer_small).apply {
            setTextViewText(R.id.notification_title_small, "Jawaban Winatra")
            setTextViewText(R.id.notification_body_small, text)
        }
        val bigRv = RemoteViews(packageName, R.layout.notification_answer).apply {
            setTextViewText(R.id.notification_title, "Jawaban Winatra")
            setTextViewText(R.id.notification_body, text)
        }

        val builder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info) // ganti pakai icon Winatra nanti
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setCustomContentView(smallRv)
            .setCustomBigContentView(bigRv)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())

        if (showKenapaButton) {
            val kenapaIntent = Intent(this, KenapaReceiver::class.java).apply {
                putExtra("alasan", lastFullAnswer)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                this, 0, kenapaIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            builder.addAction(0, "Kenapa?", pendingIntent)
        }

        (getSystemService(NotificationManager::class.java))
            .notify(System.currentTimeMillis().toInt(), builder.build())
    }

    override fun onDestroy() {
        super.onDestroy()
        floatingView?.let { windowManager.removeView(it) }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}