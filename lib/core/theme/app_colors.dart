import 'package:flutter/material.dart';

/// Palet warna resmi Winatra AI: Electric Blue + Neon.
/// SEMUA fitur baru (notifikasi, keyboard, AI popup, UI umum) wajib pakai
/// palet ini, jangan bikin warna custom lepas di luar file ini.
class AppColors {
  AppColors._();

  // Base — electric blue, dominan di background & elemen utama
  static const Color electricBlue = Color(0xFF0A2FFF);
  static const Color electricBlueDark = Color(0xFF060B26);
  static const Color electricBlueDeep = Color(0xFF01031A);

  // Neon accent — dipakai untuk highlight, glow, tombol aktif, indikator AI
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonMagenta = Color(0xFFFF2EF3);
  static const Color neonLime = Color(0xFFCFFF04);

  // Status / semantic
  static const Color success = Color(0xFF00E38C);
  static const Color warning = Color(0xFFFFC400);
  static const Color danger = Color(0xFFFF3B5C);

  // Surface & text (dark theme jadi default, cocok buat tema neon)
  static const Color surface = Color(0xFF10163B);
  static const Color surfaceElevated = Color(0xFF171E4D);
  static const Color textPrimary = Color(0xFFF5F7FF);
  static const Color textSecondary = Color(0xFFA9B2E3);

  /// Gradient khas Winatra, dipakai di splash screen, header, tombol utama.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [electricBlue, neonCyan],
  );

  /// Glow shadow buat elemen yang butuh kesan "AI aktif" (contoh: AI Popup, tombol Jawab).
  static List<BoxShadow> neonGlow({Color color = neonCyan, double blur = 20}) {
    return [
      BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: blur, spreadRadius: 1),
    ];
  }
}
