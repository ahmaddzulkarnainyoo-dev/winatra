import 'package:cloud_firestore/cloud_firestore.dart';

/// Cache jawaban di Firestore untuk menghindari panggilan API DeepSeek
/// berulang untuk soal/prompt yang identik. Blueprint 4.5.
class PromptCacheService {
  final _db = FirebaseFirestore.instance;
  final String _collection = 'promptCache';

  /// Cari jawaban yang sudah di-cache berdasarkan hash prompt.
  /// Return null jika belum ada.
  Future<String?> getCachedAnswer(String prompt) async {
    final hash = _hash(prompt);
    final doc = await _db.collection(_collection).doc(hash).get();
    if (!doc.exists) return null;
    return doc.data()?['answer'] as String?;
  }

  /// Simpan jawaban ke cache.
  Future<void> saveAnswer(String prompt, String answer) async {
    final hash = _hash(prompt);
    await _db.collection(_collection).doc(hash).set({
      'prompt': prompt,
      'answer': answer,
      'cachedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Simple hash — pakai substring dari SHA-like identifier.
  /// Cukup unik untuk deduplikasi soal persis sama.
  String _hash(String input) {
    // Gunakan kode hash sederhana + timestamp batch
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = (hash * 31 + input.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}