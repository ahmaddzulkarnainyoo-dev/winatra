import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  static const String _keyStreakCount = 'streak_count';
  static const String _keyLastActiveDate = 'last_active_date';

  /// Returns current streak count stored locally.
  Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyStreakCount) ?? 0;
  }

  /// Returns bonus kuota jika streak mencapai milestone tertentu.
  /// Milestone: 7 hari → +2, 30 hari → +5, 100 hari → +10.
  /// Return 0 jika tidak ada milestone.
  int getMilestoneBonus(int streak) {
    if (streak >= 100 && streak % 100 == 0) return 10;
    if (streak >= 30 && streak % 30 == 0) return 5;
    if (streak >= 7 && streak % 7 == 0) return 2;
    return 0;
  }

  /// Records a daily activity and updates streak based on the difference
  /// between the locally stored last_active_date and today's local date.
  ///
  /// Rules:
  /// - If last_active_date == yesterday => streak++
  /// - If last_active_date == today => streak unchanged
  /// - If last_active_date is older than yesterday (or missing) => reset to 1
  ///
  /// Returns the bonus kuota earned from milestone (0 if none).
  /// All logic uses DateTime lokal and compares dates in YYYY-MM-DD format.
  Future<int> recordActivity() async {
    final prefs = await SharedPreferences.getInstance();

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final String todayStr = _formatLocalDate(today);

    final String? lastActiveStr = prefs.getString(_keyLastActiveDate);
    final int currentStreak = prefs.getInt(_keyStreakCount) ?? 0;

    // If never active before, start streak at 1.
    if (lastActiveStr == null || lastActiveStr.isEmpty) {
      await prefs.setInt(_keyStreakCount, 1);
      await prefs.setString(_keyLastActiveDate, todayStr);
      return getMilestoneBonus(1);
    }

    final DateTime? lastActive = _tryParseLocalDate(lastActiveStr);
    if (lastActive == null) {
      // Corrupt/unexpected value => reset.
      await prefs.setInt(_keyStreakCount, 1);
      await prefs.setString(_keyLastActiveDate, todayStr);
      return getMilestoneBonus(1);
    }

    final DateTime yesterday = today.subtract(const Duration(days: 1));

    int nextStreak;
    final bool isYesterday = _isSameLocalDate(lastActive, yesterday);
    final bool isToday = _isSameLocalDate(lastActive, today);

    if (isYesterday) {
      nextStreak = (currentStreak <= 0 ? 1 : currentStreak + 1);
    } else if (isToday) {
      nextStreak = currentStreak <= 0 ? 1 : currentStreak;
    } else {
      // More than 1 day missed
      nextStreak = 1;
    }

    await prefs.setInt(_keyStreakCount, nextStreak);
    await prefs.setString(_keyLastActiveDate, todayStr);
    return getMilestoneBonus(nextStreak);
  }

  String _formatLocalDate(DateTime dt) {
    final int y = dt.year;
    final int m = dt.month;
    final int d = dt.day;
    final String mm = m.toString().padLeft(2, '0');
    final String dd = d.toString().padLeft(2, '0');
    return '$y-$mm-$dd';
  }

  DateTime? _tryParseLocalDate(String s) {
    // Expected format: YYYY-MM-DD
    final parts = s.split('-');
    if (parts.length != 3) return null;

    final int? y = int.tryParse(parts[0]);
    final int? m = int.tryParse(parts[1]);
    final int? d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;

    // Basic validation via DateTime normalization check.
    try {
      final DateTime parsed = DateTime(y, m, d);
      if (parsed.year != y || parsed.month != m || parsed.day != d) return null;
      return parsed;
    } catch (_) {
      return null;
    }
  }

  bool _isSameLocalDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

