/// Tier user sesuai blueprint section 4.1.
enum WinatraTier { free, premium, legend }

/// Merepresentasikan 1 dokumen di koleksi Firestore `users/{uid}`.
///
/// Kuota bersifat 1 pool gabungan (bukan per-fitur), reset harian,
/// KECUALI `chatbotQuotaResetAt` yang reset mingguan khusus Chatbot Winatra
/// (lihat blueprint 3.6 & 4.1).
class WinatraUser {
  final String uid;
  final WinatraTier tier;
  final String deviceId; // device-binding, 1 akun = 1 HP (4.2)

  final int dailyQuota; // sisa kuota harian gabungan
  final DateTime dailyQuotaResetAt;

  final int chatbotQuota; // kuota khusus Chatbot Winatra, reset mingguan
  final DateTime chatbotQuotaResetAt;

  final int streakCount;
  final DateTime? lastActiveAt;

  final bool hasUsedTrialPremium; // trial premium 3 hari, sekali seumur akun (4.4)
  final int referralSuccessCount; // hitung undangan yang berhasil daftar

  const WinatraUser({
    required this.uid,
    required this.tier,
    required this.deviceId,
    required this.dailyQuota,
    required this.dailyQuotaResetAt,
    required this.chatbotQuota,
    required this.chatbotQuotaResetAt,
    this.streakCount = 0,
    this.lastActiveAt,
    this.hasUsedTrialPremium = false,
    this.referralSuccessCount = 0,
  });

  /// Kuota starting sesuai tier baru daftar.
  /// Free = 7x (blueprint 4.1). Yang diundang dapat bonus +5 (referral, 4.4).
  static int startingQuota(WinatraTier tier, {bool isReferred = false}) {
    const base = 7; // TODO: isi angka Premium/Legend setelah [TBD] diputuskan
    return isReferred ? base + 5 : base;
  }

  /// Bonus kuota untuk yang MENGUNDANG setelah 3 orang berhasil daftar (4.4).
  static const int referralInviterBonus = 10;

  factory WinatraUser.fromMap(String uid, Map<String, dynamic> map) {
    return WinatraUser(
      uid: uid,
      tier: WinatraTier.values.byName(map['tier'] as String? ?? 'free'),
      deviceId: map['deviceId'] as String? ?? '',
      dailyQuota: map['dailyQuota'] as int? ?? 0,
      dailyQuotaResetAt: DateTime.fromMillisecondsSinceEpoch(
        map['dailyQuotaResetAt'] as int? ?? 0,
      ),
      chatbotQuota: map['chatbotQuota'] as int? ?? 0,
      chatbotQuotaResetAt: DateTime.fromMillisecondsSinceEpoch(
        map['chatbotQuotaResetAt'] as int? ?? 0,
      ),
      streakCount: map['streakCount'] as int? ?? 0,
      lastActiveAt: map['lastActiveAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastActiveAt'] as int)
          : null,
      hasUsedTrialPremium: map['hasUsedTrialPremium'] as bool? ?? false,
      referralSuccessCount: map['referralSuccessCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'tier': tier.name,
        'deviceId': deviceId,
        'dailyQuota': dailyQuota,
        'dailyQuotaResetAt': dailyQuotaResetAt.millisecondsSinceEpoch,
        'chatbotQuota': chatbotQuota,
        'chatbotQuotaResetAt': chatbotQuotaResetAt.millisecondsSinceEpoch,
        'streakCount': streakCount,
        'lastActiveAt': lastActiveAt?.millisecondsSinceEpoch,
        'hasUsedTrialPremium': hasUsedTrialPremium,
        'referralSuccessCount': referralSuccessCount,
      };
}
