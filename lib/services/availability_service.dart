import 'package:flutter/foundation.dart';
import '../models/availability.dart';
import 'supabase_service.dart';

/// Service for reading and writing expert availability from/to the
/// `expert_availability` table.
///
/// Schema reminder:
///   id          uuid PK
///   expert_id   uuid FK → experts.id
///   day_of_week int  0=Sunday … 6=Saturday
///   start_time  time
///   end_time    time
///   created_at  timestamptz
class AvailabilityService {
  final _supabase = SupabaseService.instance.client;

  static const _table = 'expert_availability';

  // ── READ ──────────────────────────────────────────────────────────────────

  /// Returns all availability slots for [expertId], ordered by day_of_week.
  Future<List<ExpertAvailability>> getAvailability(String expertId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('expert_id', expertId)
          .order('day_of_week');

      return (response as List)
          .map((row) => ExpertAvailability.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('AvailabilityService.getAvailability error: $e');
      rethrow;
    }
  }

  /// Real-time stream of all slots for [expertId].
  Stream<List<ExpertAvailability>> streamAvailability(String expertId) {
    return _supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('expert_id', expertId)
        .order('day_of_week')
        .map((rows) => rows
            .map((row) => ExpertAvailability.fromMap(row))
            .toList());
  }

  // ── WRITE ─────────────────────────────────────────────────────────────────

  /// Replaces ALL availability slots for [expertId] with [slots].
  ///
  /// Uses a delete-then-insert strategy so the caller doesn't have to diff
  /// existing rows.
  Future<void> setAvailability(
    String expertId,
    List<ExpertAvailability> slots,
  ) async {
    try {
      // 1. Delete all existing rows for this expert
      await _supabase.from(_table).delete().eq('expert_id', expertId);

      // 2. Insert the new rows (skip empty list – expert has no availability)
      if (slots.isNotEmpty) {
        final rows = slots.map((s) => s.toInsertMap()).toList();
        await _supabase.from(_table).insert(rows);
      }

      // 3. Sync is_available flag on the experts row
      await _syncExpertFlag(expertId, isAvailable: slots.isNotEmpty);

      debugPrint(
        '✅ AvailabilityService: saved ${slots.length} slots for $expertId',
      );
    } catch (e) {
      debugPrint('AvailabilityService.setAvailability error: $e');
      rethrow;
    }
  }

  /// Upsert (add or replace) the slot for a specific [dayOfWeek] (0=Sun…6=Sat).
  Future<void> upsertDaySlot({
    required String expertId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    try {
      // Delete the existing slot for this day (if any)
      await _supabase
          .from(_table)
          .delete()
          .eq('expert_id', expertId)
          .eq('day_of_week', dayOfWeek);

      // Insert the new slot
      await _supabase.from(_table).insert({
        'expert_id': expertId,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
      });

      await _syncExpertFlag(expertId, isAvailable: true);
    } catch (e) {
      debugPrint('AvailabilityService.upsertDaySlot error: $e');
      rethrow;
    }
  }

  /// Remove the slot for [dayOfWeek] for [expertId].
  Future<void> removeDaySlot({
    required String expertId,
    required int dayOfWeek,
  }) async {
    try {
      await _supabase
          .from(_table)
          .delete()
          .eq('expert_id', expertId)
          .eq('day_of_week', dayOfWeek);

      // Recalculate is_available
      final remaining = await getAvailability(expertId);
      await _syncExpertFlag(expertId, isAvailable: remaining.isNotEmpty);
    } catch (e) {
      debugPrint('AvailabilityService.removeDaySlot error: $e');
      rethrow;
    }
  }

  // ── QUERY HELPERS ─────────────────────────────────────────────────────────

  /// Returns true if [expertId] has any slot on [dartWeekday] (1=Mon…7=Sun)
  /// that covers [dateTime].
  Future<bool> isAvailableAt({
    required String expertId,
    required DateTime dateTime,
  }) async {
    try {
      final slots = await getAvailability(expertId);
      final slot = slots.slotForWeekday(dateTime.weekday);
      if (slot == null) return false;

      final start = _toDateTime(dateTime, slot.startTime);
      final end = _toDateTime(dateTime, slot.endTime);

      return !dateTime.isBefore(start) && !dateTime.isAfter(end);
    } catch (e) {
      debugPrint('AvailabilityService.isAvailableAt error: $e');
      return false;
    }
  }

  /// Returns the list of Dart weekdays (1-7) on which [expertId] is available.
  Future<List<int>> getAvailableDartWeekdays(String expertId) async {
    try {
      final slots = await getAvailability(expertId);
      return slots.enabledDartWeekdays;
    } catch (e) {
      debugPrint('AvailabilityService.getAvailableDartWeekdays error: $e');
      return [];
    }
  }

  // ── PRIVATE ───────────────────────────────────────────────────────────────

  /// Keep the `is_available` flag on the `experts` row in sync.
  Future<void> _syncExpertFlag(
    String expertId, {
    required bool isAvailable,
  }) async {
    try {
      await SupabaseService.instance.client
          .from('experts')
          .update({'is_available': isAvailable}).eq('id', expertId);
    } catch (e) {
      // Non-fatal – log and continue
      debugPrint('AvailabilityService._syncExpertFlag warning: $e');
    }
  }

  static DateTime _toDateTime(DateTime base, String hhmm) {
    final parts = hhmm.split(':');
    return DateTime(
      base.year,
      base.month,
      base.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}
