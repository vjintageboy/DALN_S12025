import '../models/mood_entry.dart';
class Streak {
  final String streakId;
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final int totalActivities;

  Streak({
    required this.streakId,
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    this.totalActivities = 0,
  });

  // ───────────────────────────────────────────────────────────────────────
  /// Tính streak hoàn toàn từ danh sách [MoodEntry] –
  /// **Không cần bảng phụ**.
  ///
  /// Quy tắc:
  /// • Mỗi ngày chỉ đếm 1 lần dù user log nhiều entries trong ngày.
  /// • [currentStreak] = số ngày liên tiếp tính từ hôm nay (hoặc hôm qua)
  ///   đổ về quá khứ không bị gị gián đoạn.
  /// • [longestStreak] = chuỗi dài nhất từng có trong lịch sử.
  /// • Nếu hôm nay Chưa log và hôm qua cũng chưa log → currentStreak = 0.
  // ───────────────────────────────────────────────────────────────────────
  static Streak fromMoodEntries({
    required String userId,
    required List<MoodEntry> entries,
  }) {
    if (entries.isEmpty) {
      return Streak(
        streakId: userId,
        userId: userId,
        currentStreak: 0,
        longestStreak: 0,
        lastActivityDate: null,
        totalActivities: 0,
      );
    }

    // ── Bước 1: Lấy tập hợp các ngày duy nhất đã log mood ───────────────
    // Chưa nối chuỗi vào cụm - chỉ cần biết ngày nào user đã check-in.
    final activeDays = entries
        .map((e) => DateTime(
              e.timestamp.year,
              e.timestamp.month,
              e.timestamp.day,
            ))
        .toSet()
        .toList()
      ..sort(); // tăng dần, cũ nhất trước

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));

    // ── Bước 2: Tính longest streak truyền thống ──────────────────────
    int longestStreak = 1;
    int runLength = 1;
    for (int i = 1; i < activeDays.length; i++) {
      final diff = activeDays[i].difference(activeDays[i - 1]).inDays;
      if (diff == 1) {
        runLength++;
        if (runLength > longestStreak) longestStreak = runLength;
      } else {
        runLength = 1;
      }
    }

    // ── Bước 3: Tính current streak (đếm ngược từ hôm nay / hôm qua) ───
    // Cưu đại: nếu user chưa log hôm nay nhưng đã log hôm qua,
    // chuỗi vẫn chưa bị gãy cho đến cuối ngày hôm nay.
    int currentStreak = 0;
    final lastDay = activeDays.last;

    final bool activeToday = lastDay == todayDate;
    final bool activeYesterday = lastDay == yesterday;

    if (activeToday || activeYesterday) {
      // Chạy ngược từ cuối mảng
      currentStreak = 1;
      for (int i = activeDays.length - 2; i >= 0; i--) {
        final diff = activeDays[i + 1].difference(activeDays[i]).inDays;
        if (diff == 1) {
          currentStreak++;
        } else {
          break;
        }
      }
    }
    // Nếu lastDay < yesterday -> chuỗi đã gãy, currentStreak = 0

    return Streak(
      streakId: userId,
      userId: userId,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastActivityDate: activeDays.last,
      totalActivities: entries.length, // tổng entries (không dédup)
    );
  }
}
