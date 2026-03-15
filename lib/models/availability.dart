/// Maps to one row in the `expert_availability` table.
///
/// Schema:
///   id          uuid  PK
///   expert_id   uuid  FK → experts.id
///   day_of_week int   0=Sunday … 6=Saturday
///   start_time  time  e.g. "09:00:00"
///   end_time    time  e.g. "17:00:00"
///   created_at  timestamptz
class ExpertAvailability {
  final String id;
  final String expertId;

  /// 0 = Sunday, 1 = Monday … 6 = Saturday  (matches the DB convention)
  final int dayOfWeek;

  /// "HH:mm" – trimmed from the Postgres `time` value
  final String startTime;

  /// "HH:mm"
  final String endTime;

  final DateTime? createdAt;

  const ExpertAvailability({
    required this.id,
    required this.expertId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.createdAt,
  });

  // ── Supabase helpers ────────────────────────────────────────────────────────

  factory ExpertAvailability.fromMap(Map<String, dynamic> map) {
    return ExpertAvailability(
      id: map['id']?.toString() ?? '',
      expertId: map['expert_id']?.toString() ?? '',
      dayOfWeek: (map['day_of_week'] as num?)?.toInt() ?? 0,
      startTime: _trimTime(map['start_time']?.toString() ?? '00:00'),
      endTime: _trimTime(map['end_time']?.toString() ?? '00:00'),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toInsertMap() => {
        'expert_id': expertId,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
      };

  // ── Utility ─────────────────────────────────────────────────────────────────

  /// Converts DB `day_of_week` (0=Sun) to Dart `DateTime.weekday` (1=Mon…7=Sun).
  int get dartWeekday {
    // DB: 0=Sun, 1=Mon … 6=Sat
    // Dart: 1=Mon, 2=Tue … 7=Sun
    if (dayOfWeek == 0) return DateTime.sunday; // 7
    return dayOfWeek; // 1-6 match Mon-Sat in both conventions
  }

  /// Returns a human-readable day name.
  String get dayName {
    const names = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    return names[dayOfWeek.clamp(0, 6)];
  }

  /// Strips seconds from a Postgres `time` string ("09:00:00" → "09:00").
  static String _trimTime(String t) {
    final parts = t.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return t;
  }

  @override
  String toString() =>
      'ExpertAvailability(day=$dayName, $startTime-$endTime)';
}

// ── Collection helpers ─────────────────────────────────────────────────────────

extension ExpertAvailabilityList on List<ExpertAvailability> {
  /// Returns whether the expert has ANY slot on the given [dartWeekday]
  /// (1=Mon … 7=Sun).
  bool isAvailableOnWeekday(int dartWeekday) {
    return any((slot) => slot.dartWeekday == dartWeekday);
  }

  /// Returns ALL rows for [dartWeekday], sorted by start_time.
  /// Use this to support split shifts (e.g. 09:00–12:00 + 14:00–17:00).
  List<ExpertAvailability> slotsForWeekday(int dartWeekday) {
    final matches = where((slot) => slot.dartWeekday == dartWeekday).toList();
    // Sort by start_time so slots are generated in chronological order.
    matches.sort((a, b) => a.startTime.compareTo(b.startTime));
    return matches;
  }

  /// Returns only the FIRST row for [dartWeekday], or null.
  /// For most cases prefer [slotsForWeekday] to handle split shifts.
  ExpertAvailability? slotForWeekday(int dartWeekday) {
    final all = slotsForWeekday(dartWeekday);
    return all.isEmpty ? null : all.first;
  }

  /// Returns a sorted list of distinct enabled Dart weekdays (1-7).
  List<int> get enabledDartWeekdays =>
      map((s) => s.dartWeekday).toSet().toList()..sort();
}

// ---------------------------------------------------------------------------
// BACKWARD-COMPAT SHIM
// ---------------------------------------------------------------------------
// The old `TimeSlot` and `Availability` types were referenced in schedule_page
// and booking_page. We keep lightweight versions here so callers that haven't
// been updated yet still compile. They are deprecated – prefer ExpertAvailability.

@Deprecated('Use ExpertAvailability instead')
class TimeSlot {
  final String startTime;
  final String endTime;

  TimeSlot({required this.startTime, required this.endTime});

  Map<String, dynamic> toMap() => {
        'start_time': startTime,
        'end_time': endTime,
      };

  factory TimeSlot.fromMap(Map<String, dynamic> map) => TimeSlot(
        startTime: map['start_time']?.toString() ?? '00:00',
        endTime: map['end_time']?.toString() ?? '00:00',
      );
}
