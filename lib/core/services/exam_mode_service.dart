import 'package:shared_preferences/shared_preferences.dart';

/// Simpan & baca pengaturan Mode Ujian per-user.
/// Disimpan di SharedPreferences biar ringan, tidak perlu Firestore.
class ExamModeService {
  Future<void> saveExamRange(DateTime start, DateTime end) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('exam_start', start.millisecondsSinceEpoch);
    await prefs.setInt('exam_end', end.millisecondsSinceEpoch);
  }

  /// Cek apakah user sedang dalam periode ujian aktif.
  /// Return true jika ada rentang tanggal aktif dan belum expired.
  /// Jika sudah expired, auto-reset dengan menghapus data.
  Future<bool> isInExamMode() async {
    final prefs = await SharedPreferences.getInstance();
    final endMs = prefs.getInt('exam_end');
    if (endMs == null) return false;
    final endDate = DateTime.fromMillisecondsSinceEpoch(endMs);
    final now = DateTime.now();

    // Auto-reset: jika sudah lewat tanggal akhir, hapus data dan return false
    if (now.isAfter(endDate)) {
      await prefs.remove('exam_start');
      await prefs.remove('exam_end');
      return false;
    }
    return true;
  }

  /// Membatalkan Mode Ujian secara manual (dari UI).
  Future<void> cancelExamMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('exam_start');
    await prefs.remove('exam_end');
  }

  Future<Map<String, dynamic>?> getActiveExam() async {
    final prefs = await SharedPreferences.getInstance();
    final endMs = prefs.getInt('exam_end');
    if (endMs == null) return null;
    final endDate = DateTime.fromMillisecondsSinceEpoch(endMs);
    if (DateTime.now().isAfter(endDate)) return null; // sudah lewat, dianggap tidak aktif
    return {
      'startDate': prefs.getInt('exam_start'),
      'endDate': endMs,
    };
  }
}