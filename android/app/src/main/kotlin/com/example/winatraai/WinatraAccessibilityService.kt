package com.example.winatraai

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.speech.tts.TextToSpeech
import android.view.accessibility.AccessibilityEvent
import java.util.Locale

/// Otak "kehadiran" Winatra — nyala pas user aktifin di Settings Accessibility.
/// Kasih feedback suara biar kerasa kayak asisten beneran, bukan service diam.
class WinatraAccessibilityService : AccessibilityService(), TextToSpeech.OnInitListener {

    private lateinit var tts: TextToSpeech
    private var ttsReady = false

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

    private fun speak(text: String) {
        if (ttsReady) {
            tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, "winatra_utterance")
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // TODO: di sinilah nanti logic "Winatra ngerti konteks layar kamu"
        // dikembangin — baca teks di layar buat context AI Popup, dsb.
        // Sengaja dikosongkan dulu, jangan diisi logic berat di sini,
        // event ini dipanggil SANGAT sering (tiap klik user di HP manapun).
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