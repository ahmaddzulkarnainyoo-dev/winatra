import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Simpan & baca pengaturan Mode Ujian per-user.
/// Disimpan di subcollection users/{uid}/examMode/active biar terpisah 
/// dari dokumen tier utama (yang sering ditulis/dibaca, jangan dicampur).
class ExamModeService {
  final _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> saveExamRange(DateTime start, DateTime end) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('examMode')
        .doc('active')
        .set({
      'startDate': start.millisecondsSinceEpoch,
      'endDate': end.millisecondsSinceEpoch,
      'isActive': true,
    });
  }

  /// Cek apakah user sedang dalam periode ujian aktif.
  /// Return true jika ada rentang tanggal aktif dan belum expired.
  /// Jika sudah expired, auto-reset dengan menghapus dokumen Firestore.
  Future<bool> isInExamMode() async {
    final uid = _uid;
    if (uid == null) return false;
    final docRef = _db.collection('users').doc(uid).collection('examMode').doc('active');
    final doc = await docRef.get();
    if (!doc.exists) return false;
    final data = doc.data()!;
    final endDate = DateTime.fromMillisecondsSinceEpoch(data['endDate']);
    final now = DateTime.now();
    
    // Auto-reset: jika sudah lewat tanggal akhir, hapus data dan return false
    if (now.isAfter(endDate)) {
      await docRef.delete();
      return false;
    }
    return true;
  }

  /// Membatalkan Mode Ujian secara manual (dari UI).
  Future<void> cancelExamMode() async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('examMode')
        .doc('active')
        .delete();
  }

  Future<Map<String, dynamic>?> getActiveExam() async {
    final uid = _uid;
    if (uid == null) return null;
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('examMode')
        .doc('active')
        .get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    final endDate = DateTime.fromMillisecondsSinceEpoch(data['endDate']);
    if (DateTime.now().isAfter(endDate)) return null; // sudah lewat, dianggap tidak aktif
    return data;
  }
}
