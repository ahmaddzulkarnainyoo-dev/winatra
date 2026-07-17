package com.example.winatraai.keyboard

import android.inputmethodservice.InputMethodService
import android.view.LayoutInflater
import android.view.View
import android.view.inputmethod.EditorInfo
import android.widget.TextView
import com.example.winatraai.R

class WinatraKeyboardService : InputMethodService() {

    private var keyboardView: View? = null

    // ---- Cached view references (no findViewById() at runtime) ----
    private lateinit var letterViews: Array<TextView>
    private lateinit var keyShift: TextView
    private lateinit var keySymbol: TextView
    private lateinit var keySpace: TextView
    private lateinit var keyDelete: TextView
    private lateinit var keyEnter: TextView
    private lateinit var keyWinatra: TextView
    private lateinit var keyHistory: TextView
    private lateinit var keyEmoji: TextView
    private lateinit var tvAnswerArea: TextView

    private var isShifted = false
    private var isSymbolMode = false
    private var isEmojiMode = false
    private var answerHistory = mutableListOf<String>()

    // ---- Static data ----
    companion object {
        private const val KEYCODE_WINATRA = -1001
        private const val KEYCODE_ANSWER_HISTORY = -1002

        private val LETTER_IDS = listOf(
            R.id.key_q, R.id.key_w, R.id.key_e, R.id.key_r, R.id.key_t, R.id.key_y,
            R.id.key_u, R.id.key_i, R.id.key_o, R.id.key_p,
            R.id.key_a, R.id.key_s, R.id.key_d, R.id.key_f, R.id.key_g, R.id.key_h,
            R.id.key_j, R.id.key_k, R.id.key_l,
            R.id.key_z, R.id.key_x, R.id.key_c, R.id.key_v, R.id.key_b, R.id.key_n, R.id.key_m
        )

        private val LETTER_CHARS = listOf(
            "q","w","e","r","t","y","u","i","o","p",
            "a","s","d","f","g","h","j","k","l",
            "z","x","c","v","b","n","m"
        )

        private val SYMBOL_CHARS = listOf(
            "1","2","3","4","5","6","7","8","9","0",
            "-","/",":",";","(",")","$","&","@","\"",
            ".",",","?","!","'","`"
        )

        private val EMOJI_CHARS = listOf(
            "😀","😁","😂","🤣","😃","😄","😅","😆","😉","😊",
            "😋","😎","😍","🥰","😘","😜","😝","🤑","🤗","🤩",
            "👍","👎","👊","✊","🤛","🤜","👏","🙌","🤲","🤝",
            "❤️","💔","💖","💙","💚","💛","💜","🖤","💝","💞",
            "🔥","⭐","🎯","💯","✅","❌","❓","❗","🎉","🎊"
        )
    }

    // ================================================================
    //  LIFECYCLE — inflate + cache ONCE
    // ================================================================

    override fun onCreateInputView(): View {
        keyboardView = LayoutInflater.from(this).inflate(R.layout.winatra_keyboard, null)
        val kv = keyboardView!!

        // Cache all 26 letter TextViews
        letterViews = Array(LETTER_IDS.size) { i ->
            kv.findViewById<TextView>(LETTER_IDS[i])
        }

        // Cache action / control views
        keyShift     = kv.findViewById(R.id.key_shift)
        keySymbol    = kv.findViewById(R.id.key_symbol)
        keySpace     = kv.findViewById(R.id.key_space)
        keyDelete    = kv.findViewById(R.id.key_delete)
        keyEnter     = kv.findViewById(R.id.key_enter)
        keyWinatra   = kv.findViewById(R.id.key_winatra)
        keyHistory   = kv.findViewById(R.id.key_history)
        keyEmoji     = kv.findViewById(R.id.key_emoji)
        tvAnswerArea = kv.findViewById(R.id.tv_answer_area)

        // Register click listeners ONCE
        setupClickListeners()
        updateKeyboardState()

        return kv
    }

    override fun onStartInputView(info: EditorInfo, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        // No listener re‑registration — just reset UI
        tvAnswerArea.visibility = View.GONE
        updateKeyboardState()
    }

    override fun onEvaluateFullscreenMode(): Boolean = false

    // ================================================================
    //  SETUP — listeners registered exactly once
    // ================================================================

    private fun setupClickListeners() {
        // Letter keys
        letterViews.forEachIndexed { index, tv ->
            tv.setOnClickListener { commitText(LETTER_CHARS[index]) }
        }

        keyShift.setOnClickListener {
            isShifted = !isShifted
            updateKeyboardState()
        }

        keySymbol.setOnClickListener {
            isSymbolMode = !isSymbolMode
            isEmojiMode = false
            updateKeyboardState()
        }

        keySpace.setOnClickListener { commitText(" ") }

        keyDelete.setOnClickListener {
            currentInputConnection.deleteSurroundingText(1, 0)
        }

        keyEnter.setOnClickListener {
            val action = currentInputEditorInfo.imeOptions and EditorInfo.IME_MASK_ACTION
            currentInputConnection.performEditorAction(action)
        }

        keyWinatra.setOnClickListener { showWinatraPopup() }

        keyHistory.setOnClickListener { showAnswerHistory() }

        keyEmoji.setOnClickListener {
            isEmojiMode = !isEmojiMode
            isSymbolMode = false
            updateKeyboardState()
        }
    }

    // ================================================================
    //  UI UPDATES — no findViewById(), uses cached references
    // ================================================================

    private fun updateKeyboardState() {
        val display = when {
            isEmojiMode  -> EMOJI_CHARS
            isSymbolMode -> SYMBOL_CHARS
            else         -> LETTER_CHARS
        }

        letterViews.forEachIndexed { index, tv ->
            tv.text = display[index]
        }

        keyShift.alpha = if (isShifted) 1.0f else 0.5f
    }

    // ================================================================
    //  INPUT CONNECTION
    // ================================================================

    private fun commitText(text: String) {
        val finalText = if (isShifted && text.length == 1) {
            text.uppercase()
        } else {
            text
        }
        currentInputConnection.commitText(finalText, 1)

        // Auto‑dismiss shift after one uppercase letter
        if (isShifted && text.length == 1) {
            isShifted = false
            updateKeyboardState()
        }
    }

    // ================================================================
    //  WINATRA POPUP / HISTORY
    // ================================================================

    private fun showWinatraPopup() {
        tvAnswerArea.text = "Ketik pertanyaanmu di kolom teks, lalu tekan Enter"
        tvAnswerArea.visibility = View.VISIBLE
    }

    private fun showAnswerHistory() {
        if (answerHistory.isEmpty()) {
            tvAnswerArea.text = "Belum ada riwayat jawaban."
        } else {
            tvAnswerArea.text = answerHistory.joinToString("\n\n")
        }
        tvAnswerArea.visibility = View.VISIBLE
    }
}