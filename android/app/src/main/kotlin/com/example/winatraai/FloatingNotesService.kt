package com.example.winatraai

import android.app.*
import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.graphics.PixelFormat
import android.os.Build
import android.widget.Toast
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import android.os.*
import android.view.Gravity
import android.view.LayoutInflater
import android.view.WindowManager
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.ImageButton
import android.widget.RemoteViews
import android.widget.Spinner
import android.widget.TextView
import androidx.core.app.NotificationCompat
import androidx.media.app.NotificationCompat.MediaStyle
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FieldValue
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class FloatingNotesService : Service() {
    private lateinit var windowManager: WindowManager
    private var floatingView: android.view.View? = null
    private var currentMode: String = "pelajar"
    private var floatingMode: Boolean = true
    private var lastFullAnswer: String = "" // cache buat tombol "Kenapa?", gak perlu API call ulang
    private var selectedMapel: String = "Umum"
    private var lastRequestTime: Long = 0L
    private val minRequestInterval = 5000L // 5 detik rate-limit

    private val workerUrl = "https://winatraai.himlabnews.workers.dev"
    private val channelId = "winatra_answers"
    private val persistentChannelId = "winatra_persistent"

    private val mapelList = arrayOf(
        "Umum", "Matematika SD", "Matematika SMP", "Matematika SMA", "Matematika Kuliah",
        "Fisika SD", "Fisika SMP", "Fisika SMA", "Fisika Kuliah",
        "Kimia SMA", "Kimia Kuliah",
        "Biologi SD", "Biologi SMP", "Biologi SMA", "Biologi Kuliah",
        "Bahasa Indonesia", "Bahasa Inggris",
        "Sejarah", "Geografi", "Ekonomi", "Sosiologi",
        "Agama", "PKN", "TIK", "Seni Budaya", "PJOK"
    )

    private var jawabReceiverRegistered = false
    private val jawabReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == "com.winatraai.JAWAB_ACTION") {
                handleJawabClicked()
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        val wm = getSystemService(WINDOW_SERVICE) as? WindowManager
        if (wm == null) {
            android.util.Log.e("FloatingNotesService", "windowManager is null — cannot create service")
            stopSelf()
            return
        }
        windowManager = wm
        createNotificationChannel()
        createPersistentChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!::windowManager.isInitialized) {
            android.util.Log.e("FloatingNotesService", "windowManager not initialized")
            stopSelf()
            return START_NOT_STICKY
        }

        currentMode = intent?.getStringExtra("mode") ?: currentMode
        floatingMode = intent?.getBooleanExtra("floatingMode", true) ?: true

        if (floatingMode) {
            // Mode floating: tampilkan bubble overlay
            if (floatingView == null) {
                try {
                    showFloatingWidget()
                } catch (e: Exception) {
                    android.util.Log.e("FloatingNotesService", "Gagal show floating widget", e)
                    stopSelf()
                    return START_NOT_STICKY
                }
            }
            updateButtonsForMode()
            // Hentikan persistent notification jika sebelumnya non-floating
            stopForeground(STOP_FOREGROUND_REMOVE)
            unregisterJawabReceiver()
        } else {
            // Mode non-floating: tampilkan persistent notification dengan tombol Jawab
            try {
                floatingView?.let {
                    if (::windowManager.isInitialized) {
                        windowManager.removeView(it)
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e("FloatingNotesService", "Gagal remove floating view", e)
            }
            floatingView = null
            showPersistentNotification()
            registerJawabReceiver()
        }

        return START_STICKY
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            channelId, "Jawaban Winatra", NotificationManager.IMPORTANCE_HIGH
        )
        (getSystemService(NotificationManager::class.java)).createNotificationChannel(channel)
    }

    private fun createPersistentChannel() {
        val channel = NotificationChannel(
            persistentChannelId, "Winatra", NotificationManager.IMPORTANCE_LOW
        ).apply {
            setShowBadge(false)
            setSound(null, null)
            vibrationPattern = null
        }
        (getSystemService(NotificationManager::class.java)).createNotificationChannel(channel)
    }

    private fun registerJawabReceiver() {
        if (!jawabReceiverRegistered) {
            registerReceiver(jawabReceiver, IntentFilter("com.winatraai.JAWAB_ACTION"), RECEIVER_NOT_EXPORTED)
            jawabReceiverRegistered = true
        }
    }

    private fun unregisterJawabReceiver() {
        if (jawabReceiverRegistered) {
            try {
                unregisterReceiver(jawabReceiver)
            } catch (_: Exception) {}
            jawabReceiverRegistered = false
        }
    }

    fun updateMode(mode: String) {
        currentMode = mode
        // Update floating widget buttons if visible
        if (floatingView != null) {
            updateButtonsForMode()
        }
        // Update persistent notification title
        if (!floatingMode && ::windowManager.isInitialized) {
            showPersistentNotification()
        }
    }

    private fun showPersistentNotification() {
        try {
            // Cek izin Android 13+ (POST_NOTIFICATIONS)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                    != PackageManager.PERMISSION_GRANTED
                ) {
                    android.util.Log.w("FloatingNotesService", "POST_NOTIFICATIONS tidak diizinkan — fallback ke Toast")
                    Toast.makeText(this, "Aktifkan notifikasi untuk Winatra di Pengaturan agar mode non-floating berfungsi.", Toast.LENGTH_LONG).show()
                    // Tetap jalan, hanya log warning — tidak hentikan service
                }
            }

            // Cek apakah notifikasi diizinkan secara umum
            if (!NotificationManagerCompat.areNotificationsEnabled(this)) {
                android.util.Log.w("FloatingNotesService", "Notifikasi tidak diizinkan — persistent notification tidak muncul")
                Toast.makeText(this, "Aktifkan notifikasi untuk Winatra di Pengaturan agar mode non-floating berfungsi.", Toast.LENGTH_LONG).show()
            }

            // Intent untuk tombol Jawab — broadcast ke receiver
            val jawabIntent = Intent("com.winatraai.JAWAB_ACTION")
            val jawabPendingIntent = PendingIntent.getBroadcast(
                this, 1, jawabIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Intent untuk tombol Buka — buka MainActivity
            val bukaIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val bukaPendingIntent = PendingIntent.getActivity(
                this, 2, bukaIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Large icon dari launcher icon
            val largeIcon = BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher)

            val notification = NotificationCompat.Builder(this, persistentChannelId)
                .setSmallIcon(R.drawable.ic_notification)
                .setLargeIcon(largeIcon)
                .setContentTitle("Winatra AI Aktif")
                .setContentText("Ketik & tanya langsung dari sini")
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setCategory(NotificationCompat.CATEGORY_SERVICE)
                .setOngoing(true)
                .setColor(0xFF00BFFF.toInt())
                .setStyle(MediaStyle())
                .addAction(android.R.drawable.ic_menu_edit, "Jawab", jawabPendingIntent)
                .addAction(android.R.drawable.ic_menu_compass, "Buka", bukaPendingIntent)
                .build()

            startForeground(1001, notification)
        } catch (e: Exception) {
            android.util.Log.e("FloatingNotesService", "Gagal show persistent notification", e)
        }
    }

    private fun showFloatingWidget() {
        try {
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
            
            val closeButton = floatingView?.findViewById<ImageButton>(R.id.btnClose)
            closeButton?.setOnClickListener {
                floatingView?.let { windowManager.removeView(it) }
                stopSelf()
            }

            updateButtonsForMode()
        } catch (e: SecurityException) {
            android.util.Log.e("FloatingNotesService", "SecurityException: overlay permission tidak aktif", e)
            stopSelf()
        } catch (e: Exception) {
            android.util.Log.e("FloatingNotesService", "Gagal menampilkan floating widget", e)
            stopSelf()
        }
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

        // Cek dailyQuota dari Firestore sebelum callWorker
        val uid = getSharedPreferencesUid()
        if (uid == null) {
            showAnswerNotification("Gagal: user tidak terautentikasi.", showKenapaButton = false)
            return
        }

        Thread {
            try {
                val db = FirebaseFirestore.getInstance()
                val doc = db.collection("users").document(uid).get().await()
                val dailyQuota = doc.getLong("dailyQuota") ?: 0
                if (dailyQuota <= 0) {
                    showAnswerNotification("Kuota harian habis! Reset besok, atau upgrade ke Premium.", showKenapaButton = false)
                    return@Thread
                }

                val result = callWorker(prompt)
                val lines = result.split("\n", limit = 2)

                // Kurangi dailyQuota setelah jawaban berhasil didapat
                db.collection("users").document(uid).update("dailyQuota", FieldValue.increment(-1))

                // Tampilkan indikator tipe soal di floating widget
                updateSoalType(isPilihanGanda)

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
            } catch (e: Exception) {
                android.util.Log.e("FloatingNotesService", "Error handleJawabClicked", e)
                showAnswerNotification("Gagal: ${e.message}", showKenapaButton = false)
            }
        }.start()
    }

    private fun getSharedPreferencesUid(): String? {
        val prefs = getSharedPreferences("com.winatraai.prefs", Context.MODE_PRIVATE)
        return prefs.getString("uid", null)
    }

    private fun updateSoalType(isPilihanGanda: Boolean) {
        val tvSoalType = floatingView?.findViewById<TextView>(R.id.tvSoalType)
        if (tvSoalType != null) {
            tvSoalType.text = if (isPilihanGanda) "Pilihan Ganda" else "Essay"
            tvSoalType.visibility = android.view.View.VISIBLE
        }
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
        try {
            val nm = getSystemService(NotificationManager::class.java) ?: return
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

            nm.notify(System.currentTimeMillis().toInt(), builder.build())
        } catch (e: Exception) {
            android.util.Log.e("FloatingNotesService", "Gagal show answer notification", e)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            if (::windowManager.isInitialized) {
                floatingView?.let { windowManager.removeView(it) }
            }
        } catch (e: Exception) {
            android.util.Log.e("FloatingNotesService", "Gagal cleanup di onDestroy", e)
        }
        floatingView = null
        unregisterJawabReceiver()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}