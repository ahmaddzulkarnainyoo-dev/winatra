package com.example.winatraai.keyboard

import android.inputmethodservice.InputMethodService
import android.view.LayoutInflater
import android.view.View
import android.view.inputmethod.EditorInfo
import android.widget.TextView
import com.example.winatraai.R

class WinatraKeyboardService : InputMethodService() {

    private var keyboardView: View? = null
    private var isShifted = false
    private var isSymbolMode = false
    private var isEmojiMode = false
    private var answerHistory = mutableListOf<String>()

    companion object {
        private const val KEYCODE_WINATRA = -1001
        private const val KEYCODE_ANSWER_HISTORY = -1002
    }

    override fun onCreateInputView(): View {
        keyboardView = LayoutInflater.from(this).inflate(R.layout.winatra_keyboard, null)
        setupKeyboardButtons()
        return keyboardView!!
    }

    override fun onStartInputView(info: EditorInfo, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        setupKeyboardButtons()
    }

    override fun onEvaluateFullscreenMode(): Boolean = false

    private fun setupKeyboardButtons() {
        val keyboard = keyboardView ?: return
        
        // Tombol huruf A-Z
        val letterKeys = listOf(
            "q","w","e","r","t","y","u","i","o","p",
            "a","s","d","f","g","h","j","k","l",
            "z","x","c","v","b","n","m"
        )
        val letterIds = listOf(
            R.id.key_q, R.id.key_w, R.id.key_e, R.id.key_r, R.id.key_t, R.id.key_y,
            R.id.key_u, R.id.key_i, R.id.key_o, R.id.key_p,
            R.id.key_a, R.id.key_s, R.id.key_d, R.id.key_f, R.id.key_g, R.id.key_h,
            R.id.key_j, R.id.key_k, R.id.key_l,
            R.id.key_z, R.id.key_x, R.id.key_c, R.id.key_v, R.id.key_b, R.id.key_n, R.id.key_m
        )
        
        letterIds.forEachIndexed { index, id ->
            keyboard.findViewById<View>(id)?.setOnClickListener {
                commitText(letterKeys[index])
            }
        }

        // Shift
        keyboard.findViewById<View>(R.id.key_shift)?.setOnClickListener {
            isShifted = !isShifted
            updateShiftState()
        }

        // Symbol mode
        keyboard.findViewById<View>(R.id.key_symbol)?.setOnClickListener {
            isSymbolMode = !isSymbolMode
            updateSymbolState()
        }

        // Space
        keyboard.findViewById<View>(R.id.key_space)?.setOnClickListener {
            commitText(" ")
        }

        // Delete
        keyboard.findViewById<View>(R.id.key_delete)?.setOnClickListener {
            currentInputConnection.deleteSurroundingText(1, 0)
        }

        // Enter
        keyboard.findViewById<View>(R.id.key_enter)?.setOnClickListener {
            val action = currentInputEditorInfo.imeOptions and EditorInfo.IME_MASK_ACTION
            currentInputConnection.performEditorAction(action)
        }

        // Winatra AI button
        keyboard.findViewById<View>(R.id.key_winatra)?.setOnClickListener {
            showWinatraPopup()
        }

        // Answer history button
        keyboard.findViewById<View>(R.id.key_history)?.setOnClickListener {
            showAnswerHistory()
        }

        // Emoji mode button
        keyboard.findViewById<View>(R.id.key_emoji)?.setOnClickListener {
            isEmojiMode = !isEmojiMode
            updateEmojiState()
        }

        updateShiftState()
        updateSymbolState()
    }

    private fun commitText(text: String) {
        val finalText = if (isShifted && text.length == 1) {
            text.uppercase()
        } else {
            text
        }
        currentInputConnection.commitText(finalText, 1)
        if (isShifted && text.length == 1) {
            isShifted = false
            updateShiftState()
        }
    }

    private fun updateShiftState() {
        keyboardView?.findViewById<View>(R.id.key_shift)?.alpha = if (isShifted) 1.0f else 0.5f
    }

    private fun updateSymbolState() {
        if (isEmojiMode) return // emoji mode handle sendiri

        val letterKeys = listOf(
            R.id.key_q, R.id.key_w, R.id.key_e, R.id.key_r, R.id.key_t, R.id.key_y,
            R.id.key_u, R.id.key_i, R.id.key_o, R.id.key_p,
            R.id.key_a, R.id.key_s, R.id.key_d, R.id.key_f, R.id.key_g, R.id.key_h,
            R.id.key_j, R.id.key_k, R.id.key_l,
            R.id.key_z, R.id.key_x, R.id.key_c, R.id.key_v, R.id.key_b, R.id.key_n, R.id.key_m
        )
        val symbols = if (isSymbolMode) {
            listOf("1","2","3","4","5","6","7","8","9","0",
                   "-","/",":",";","(",")","$","&","@","\"",
                   ".",",","?","!","'","`")
        } else {
            listOf("q","w","e","r","t","y","u","i","o","p",
                   "a","s","d","f","g","h","j","k","l",
                   "z","x","c","v","b","n","m")
        }
        letterKeys.forEachIndexed { index, id ->
            (keyboardView?.findViewById<TextView>(id))?.text = symbols[index]
        }
    }

    private fun updateEmojiState() {
        val emojiList = listOf(
            "😀","😁","😂","🤣","😃","😄","😅","😆","😉","😊",
            "😋","😎","😍","🥰","😘","😜","😝","🤑","🤗","🤩",
            "👍","👎","👊","✊","🤛","🤜","👏","🙌","🤲","🤝",
            "❤️","💔","💖","💙","💚","💛","💜","🖤","💝","💞",
            "🔥","⭐","🎯","💯","✅","❌","❓","❗","🎉","🎊"
        )
        val letterIds = listOf(
            R.id.key_q, R.id.key_w, R.id.key_e, R.id.key_r, R.id.key_t, R.id.key_y,
            R.id.key_u, R.id.key_i, R.id.key_o, R.id.key_p,
            R.id.key_a, R.id.key_s, R.id.key_d, R.id.key_f, R.id.key_g, R.id.key_h,
            R.id.key_j, R.id.key_k, R.id.key_l,
            R.id.key_z, R.id.key_x, R.id.key_c, R.id.key_v, R.id.key_b, R.id.key_n, R.id.key_m
        )
        val display = if (isEmojiMode) emojiList else {
            if (isSymbolMode) listOf("1","2","3","4","5","6","7","8","9","0",
                   "-","/",":",";","(",")","$","&","@","\"",
                   ".",",","?","!","'","`")
            else listOf("q","w","e","r","t","y","u","i","o","p",
                   "a","s","d","f","g","h","j","k","l",
                   "z","x","c","v","b","n","m")
        }
        letterIds.forEachIndexed { index, id ->
            (keyboardView?.findViewById<TextView>(id))?.text = if (index < display.size) display[index] else ""
        }
    }

    private fun showWinatraPopup() {
        // Tampilkan area input di atas keyboard untuk bertanya ke AI
        val answerArea = keyboardView?.findViewById<TextView>(R.id.tv_answer_area)
        answerArea?.text = "Ketik pertanyaanmu di kolom teks, lalu tekan Enter"
        answerArea?.visibility = View.VISIBLE
    }

    private fun showAnswerHistory() {
        val answerArea = keyboardView?.findViewById<TextView>(R.id.tv_answer_area)
        if (answerHistory.isEmpty()) {
            answerArea?.text = "Belum ada riwayat jawaban."
        } else {
            answerArea?.text = answerHistory.joinToString("\n\n")
        }
        answerArea?.visibility = View.VISIBLE
    }
}