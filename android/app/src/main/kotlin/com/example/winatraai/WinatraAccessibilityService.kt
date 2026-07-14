package com.example.winatraai

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.provider.Settings
import android.speech.tts.TextToSpeech
import android.view.accessibility.AccessibilityEvent
import java.util.Locale

/// Otak "kehadiran" Winatra — nyala pas user aktifin di Settings Accessibility.
/// Kasih feedback suara biar kerasa kayak asisten beneran, bukan service diam.
class WinatraAccessibilityService : AccessibilityService(), TextToSpeech.OnInitListener {

    private lateinit var tts: TextToSpeech
    private var ttsReady = false
    
    // 3x tap gesture recovery
    private var tapCount = 0
    private var lastTapTime = 0L
    private val tapWindow = 800L // 800ms window untuk 3 tap

    override fun onServiceConnected() {
        super.onServiceConnected()

        // Konfigurasi apa yang mau "didengar" service ini dari layar user
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_VIEW_CLICKED or
                    AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 100
        }
        serviceInfo = info

        tts = TextToSpeech(this, this)
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            tts.language = Locale("id", "ID")
            ttsReady = true
            speak("Winatra aktif. Siap bantu kamu.")
        }
    }

    /// Teks yang terakhir terbaca dari layar — bisa dipakai AI Popup atau fitur lain.
    private var lastScreenText: String = ""

    val screenText: String get() = lastScreenText

    private fun speak(text: String) {
        if (ttsReady) {
            tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, "winatra_utterance")
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        // Baca teks dari event untuk screen reading — simpan buat konteks
        val eventText = event.text?.joinToString(" ") ?: ""
        if (eventText.isNotBlank()) {
            lastScreenText = eventText
        }

        // Kalau ada konten description (contentDescription dari view), gabungin juga
        val contentDesc = event.contentDescription?.toString() ?: ""
        if (contentDesc.isNotBlank()) {
            lastScreenText = "$lastScreenText $contentDesc"
        }

        // 3x tap gesture recovery — deteksi 3 tap cepat di mana saja di layar
        if (event.eventType == AccessibilityEvent.TYPE_VIEW_CLICKED) {
            val now = System.currentTimeMillis()
            if (now - lastTapTime < tapWindow) {
                tapCount++
            } else {
                tapCount = 1
            }
            lastTapTime = now
            
            if (tapCount >= 3) {
                tapCount = 0
                // Buka IME picker (pilih keyboard)
                val intent = Intent(Settings.ACTION_INPUT_METHOD_SETTINGS)
                intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                speak("Keyboard Winatra siap dipilih.")
            }
        }
    }

    override fun onInterrupt() {
        speak("Winatra nonaktif sementara.")
    }

    override fun onDestroy() {
        super.onDestroy()
        if (::tts.isInitialized) {
            tts.stop()
            tts.shutdown()
        }
    }
}