import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/otak_model.dart';

class OtakService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  /// Ambil semua dokumen Otak milik user, diurutkan descending berdasarkan uploadedAt.
  Future<List<Otak>> fetchUserOtaks(String userId) async {
    try {
      final snapshot = await _db
          .collection('otaks')
          .where('userId', isEqualTo: userId)
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Otak.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil daftar Otak: $e');
    }
  }

  /// Upload file ke Firebase Storage, simpan metadata ke Firestore, kembalikan Otak object.
  Future<Otak> uploadFile(
      String userId, String filePath, String fileName) async {
    try {
      final file = File(filePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'otaks/$userId/${timestamp}_$fileName';

      // Upload ke Firebase Storage
      final uploadTask = await _storage.ref(storagePath).putFile(file);
      final fileUrl = await uploadTask.ref.getDownloadURL();

      // Dapatkan ukuran file
      final fileSize = await file.length();

      // Buat dokumen di Firestore
      final docRef = await _db.collection('otaks').add({
        'userId': userId,
        'fileName': fileName,
        'fileSize': fileSize,
        'fileUrl': fileUrl,
        'storagePath': storagePath,
        'summary': '',
        'uploadedAt': FieldValue.serverTimestamp(),
        'topics': [],
        'folderId': null,
      });

      // Ambil dokumen yang baru dibuat untuk mendapatkan timestamp dari server
      final docSnapshot = await docRef.get();
      final data = docSnapshot.data()!;

      return Otak(
        id: docRef.id,
        userId: userId,
        fileName: fileName,
        fileSize: fileSize,
        fileUrl: fileUrl,
        storagePath: storagePath,
        summary: '',
        uploadedAt: (data['uploadedAt'] as dynamic).toDate(),
        topics: [],
        folderId: null,
      );
    } catch (e) {
      throw Exception('Gagal upload file: $e');
    }
  }

  /// Hapus dokumen Firestore dan file Storage.
  Future<void> deleteOtak(String otakId, String storagePath) async {
    try {
      // Hapus file dari Storage
      await _storage.ref(storagePath).delete();

      // Hapus dokumen dari Firestore
      await _db.collection('otaks').doc(otakId).delete();
    } catch (e) {
      throw Exception('Gagal menghapus Otak: $e');
    }
  }
}