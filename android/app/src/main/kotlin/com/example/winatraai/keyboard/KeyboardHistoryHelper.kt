package com.example.winatraai.keyboard

import android.content.Context
import android.content.SharedPreferences

class KeyboardHistoryHelper(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences("keyboard_history", Context.MODE_PRIVATE)

    fun getHistory(): List<String> {
        val raw = prefs.getString("history", "") ?: ""
        return if (raw.isEmpty()) emptyList() else raw.split("|||")
    }

    fun addEntry(entry: String) {
        val current = getHistory().toMutableList()
        current.add(entry)
        // Simpan max 20 entry
        val trimmed = if (current.size > 20) current.takeLast(20) else current
        prefs.edit().putString("history", trimmed.joinToString("|||")).apply()
    }
}