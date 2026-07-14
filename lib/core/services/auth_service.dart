import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/user_tier.dart';

/// Satu pintu untuk semua operasi auth + provisioning user baru.
/// JANGAN panggil FirebaseAuth/Firestore langsung dari screen manapun,
/// selalu lewat class ini biar logic tier/kuota konsisten.
class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<String?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final deviceError = await _checkAndBindDevice(cred.user!.uid);
      if (deviceError != null) {
        await _auth.signOut(); // batalkan sesi, device tidak cocok
        return deviceError;
      }
      return null; // null = sukses
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    }
  }

  Future<String?> signUp(String email, String password, {String? referredBy}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _createUserDoc(cred.user!.uid, isReferred: referredBy != null);
      if (referredBy != null) {
        await _applyReferral(referredBy);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    }
  }

  Future<void> _createUserDoc(String uid, {bool isReferred = false}) async {
    final now = DateTime.now();
    final deviceId = await _getDeviceId();
    final user = WinatraUser(
      uid: uid,
      tier: WinatraTier.free,
      deviceId: deviceId,
      dailyQuota: WinatraUser.startingQuota(WinatraTier.free, isReferred: isReferred),
      dailyQuotaResetAt: now,
      chatbotQuota: 5,
      chatbotQuotaResetAt: now,
    );
    await _db.collection('users').doc(uid).set(user.toMap());
  }

  /// Device-binding: 1 akun = 1 HP (blueprint 4.2).
  /// null = lolos (device cocok atau baru di-bind). Non-null = pesan error, device beda.
  Future<String?> _checkAndBindDevice(String uid) async {
    final currentDeviceId = await _getDeviceId();
    final docRef = _db.collection('users').doc(uid);
    final doc = await docRef.get();
    final storedDeviceId = doc.data()?['deviceId'] as String? ?? '';

    if (storedDeviceId.isEmpty) {
      // Belum terikat device manapun (akun baru / abis logout) -> bind sekarang.
      await docRef.update({'deviceId': currentDeviceId});
      return null;
    }
    if (storedDeviceId == currentDeviceId) {
      return null; // device sama, lolos
    }
    return 'Akun ini sedang aktif di perangkat lain. Logout dulu di perangkat tersebut sebelum masuk di sini.';
  }

  Future<String> _getDeviceId() async {
    final info = await DeviceInfoPlugin().androidInfo;
    return info.id; // Settings.Secure.ANDROID_ID, gak perlu permission tambahan
  }

  Future<void> _applyReferral(String inviterUid) async {
    final inviterRef = _db.collection('users').doc(inviterUid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(inviterRef);
      if (!snap.exists) return;
      final currentCount = (snap.data()?['referralSuccessCount'] ?? 0) as int;
      final newCount = currentCount + 1;
      final updates = <String, dynamic>{'referralSuccessCount': newCount};
      if (newCount % 3 == 0) {
        final currentQuota = (snap.data()?['dailyQuota'] ?? 0) as int;
        updates['dailyQuota'] = currentQuota + WinatraUser.referralInviterBonus;
      }
      tx.update(inviterRef, updates);
    });
  }

  Future<WinatraUser?> fetchCurrentUserDoc() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return WinatraUser.fromMap(uid, doc.data()!);
  }

  Future<void> signOut() async {
    final uid = currentUser?.uid;
    if (uid != null) {
      // Lepas ikatan device biar bisa login di HP lain setelah ini.
      await _db.collection('users').doc(uid).update({'deviceId': ''});
    }
    await _auth.signOut();
  }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar.';
      case 'weak-password':
        return 'Password terlalu lemah, minimal 6 karakter.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      default:
        return 'Terjadi kesalahan, coba lagi.';
    }
  }
}