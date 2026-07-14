import 'package:flutter/material.dart';
import 'package:winatraai/core/services/exam_mode_service.dart';

/// Pusat notifikasi Winatra — semua notifikasi harus lewat sini.
/// Otomatis cek Mode Ujian: jika sedang ujian aktif, notifikasi non-esensial
/// (daily briefing, promo, upsell) di-supress. Hanya notifikasi "Jawab" yang lolos.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _examMode = ExamModeService();

  /// Tampilkan notifikasi di dalam app (SnackBar).
  /// [essential] = true untuk notifikasi yang harus tetap muncul (jawaban, mode aktif).
  /// [essential] = false untuk notifikasi non-esensial (promo, briefing, upsell).
  Future<void> showSnackBar(
    BuildContext context, {
    required String message,
    bool essential = false,
    Duration duration = const Duration(seconds: 3),
  }) async {
    if (!essential) {
      final isExam = await _examMode.isInExamMode();
      if (isExam) return; // suppress non-essential saat ujian
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: duration),
    );
  }
}