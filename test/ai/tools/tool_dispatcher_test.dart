import 'package:flutter_test/flutter_test.dart';
import 'package:n04_app/ai/tools/tool_dispatcher.dart';
import 'package:n04_app/models/appointment.dart';
import 'package:n04_app/models/availability.dart';

// ---------------------------------------------------------------------------
// Helpers to build a ToolDispatcher with sensible defaults.
// Each parameter can be overridden per-test.
// ---------------------------------------------------------------------------

const _userId = 'user-123';
const _expertId = 'expert-abc';

/// Monday (Dart weekday = 1, DB day_of_week = 1)
final _monday = DateTime(2024, 4, 1); // 2024-04-01 is a Monday

ExpertAvailability _mondaySlot({
  String startTime = '09:00',
  String endTime = '17:00',
}) =>
    ExpertAvailability(
      id: 'slot-1',
      expertId: _expertId,
      dayOfWeek: 1, // Monday in DB
      startTime: startTime,
      endTime: endTime,
    );

ToolDispatcher _dispatcher({
  Future<List<ExpertAvailability>> Function(String)? getAvailability,
  Future<List<String>> Function(String, DateTime)? getBookedTimeSlots,
  List<String> Function({
    required String startTime,
    required String endTime,
    required int intervalMinutes,
  })? generateTimeSlots,
  Future<String?> Function(Appointment)? createAppointment,
  Future<List<Appointment>> Function(String)? getUserAppointments,
  Future<List<Map<String, dynamic>>> Function(String, DateTime, DateTime)?
      getMoodEntries,
  Future<Map<String, dynamic>?> Function(String)? getExpertPrice,
  Future<List<Map<String, dynamic>>?> Function(String, String, DateTime)?
      checkExistingAppointment,
  String? userId,
}) {
  return ToolDispatcher(
    getAvailability:
        getAvailability ?? (_) async => [_mondaySlot()],
    getBookedTimeSlots: getBookedTimeSlots ?? (_, __) async => [],
    generateTimeSlots: generateTimeSlots ??
        ({
          required String startTime,
          required String endTime,
          required int intervalMinutes,
        }) =>
            ['09:00', '10:00', '11:00'],
    createAppointment: createAppointment ?? (_) async => 'new-appt-id',
    getUserAppointments: getUserAppointments ?? (_) async => [],
    getMoodEntries: getMoodEntries ?? (_, __, ___) async => [],
    getExpertPrice:
        getExpertPrice ?? (_) async => {'hourly_rate': 200000},
    checkExistingAppointment:
        checkExistingAppointment ?? (_, __, ___) async => [],
    userId: userId ?? _userId,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── 1. check_expert_availability: expert has availability on date ──────────
  test('1. check_expert_availability returns available slots', () async {
    final dispatcher = _dispatcher(
      getAvailability: (_) async => [_mondaySlot()],
      getBookedTimeSlots: (_, __) async => ['10:00'],
      generateTimeSlots: ({
        required startTime,
        required endTime,
        required intervalMinutes,
      }) =>
          ['09:00', '10:00', '11:00'],
    );

    final result = await dispatcher.dispatch('check_expert_availability', {
      'expert_id': _expertId,
      'date': '2024-04-01', // Monday
      'duration_minutes': 60,
    });

    expect(result['available_slots'], isA<List>());
    final slots = result['available_slots'] as List;
    expect(slots, containsAll(['09:00', '11:00']));
    expect(slots, isNot(contains('10:00'))); // booked
  });

  // ── 2. check_expert_availability: date outside work days ──────────────────
  test('2. check_expert_availability returns empty slots for off-day', () async {
    // Sunday (2024-04-07) has no availability (expert only works Monday)
    final dispatcher = _dispatcher(
      getAvailability: (_) async => [_mondaySlot()],
    );

    final result = await dispatcher.dispatch('check_expert_availability', {
      'expert_id': _expertId,
      'date': '2024-04-07', // Sunday
    });

    final slots = result['available_slots'] as List;
    expect(slots, isEmpty);
    expect(result['message'], isNotNull);
  });

  // ── 3. book_session success ────────────────────────────────────────────────
  test('3. book_session success returns appointment_id and pending status',
      () async {
    final dispatcher = _dispatcher(
      createAppointment: (_) async => 'created-appt-id',
      getExpertPrice: (_) async => {'hourly_rate': 200000},
      checkExistingAppointment: (_, __, ___) async => [],
    );

    final result = await dispatcher.dispatch('book_session', {
      'expert_id': _expertId,
      'appointment_date': '2024-04-01T10:00:00.000',
      'duration_minutes': 60,
      'call_type': 'video',
    });

    expect(result['success'], isTrue);
    expect(result['appointment_id'], 'created-appt-id');
    expect(result['status'], 'pending');
    expect(result['price'], isA<double>());
  });

  // ── 4. book_session idempotency ────────────────────────────────────────────
  test('4. book_session returns existing appointment with idempotent:true',
      () async {
    final existingAppt = {
      'id': 'existing-appt-id',
      'status': 'confirmed',
    };

    final dispatcher = _dispatcher(
      checkExistingAppointment: (_, __, ___) async => [existingAppt],
    );

    final result = await dispatcher.dispatch('book_session', {
      'expert_id': _expertId,
      'appointment_date': '2024-04-01T10:00:00.000',
      'duration_minutes': 60,
      'call_type': 'video',
    });

    expect(result['success'], isTrue);
    expect(result['appointment_id'], 'existing-appt-id');
    expect(result['status'], 'confirmed');
    expect(result['idempotent'], isTrue);
  });

  // ── 5. book_session TIME_CONFLICT from createAppointment ──────────────────
  test('5. book_session returns TIME_CONFLICT when createAppointment throws',
      () async {
    final dispatcher = _dispatcher(
      createAppointment: (_) async =>
          throw Exception('Chuyên gia không rảnh vào giờ này'),
      checkExistingAppointment: (_, __, ___) async => [],
      getExpertPrice: (_) async => {'hourly_rate': 200000},
    );

    final result = await dispatcher.dispatch('book_session', {
      'expert_id': _expertId,
      'appointment_date': '2024-04-01T10:00:00.000',
      'duration_minutes': 60,
      'call_type': 'video',
    });

    expect(result['error'], 'TIME_CONFLICT');
    expect(result['message'], isNotNull);
  });

  // ── 6. book_session invalid duration ──────────────────────────────────────
  test('6. book_session returns INVALID_DURATION for 45-minute booking',
      () async {
    final dispatcher = _dispatcher();

    final result = await dispatcher.dispatch('book_session', {
      'expert_id': _expertId,
      'appointment_date': '2024-04-01T10:00:00.000',
      'duration_minutes': 45,
      'call_type': 'video',
    });

    expect(result['error'], 'INVALID_DURATION');
  });

  // ── 7. book_session invalid call_type ─────────────────────────────────────
  test('7. book_session returns INVALID_CALL_TYPE for phone booking', () async {
    final dispatcher = _dispatcher();

    final result = await dispatcher.dispatch('book_session', {
      'expert_id': _expertId,
      'appointment_date': '2024-04-01T10:00:00.000',
      'duration_minutes': 60,
      'call_type': 'phone',
    });

    expect(result['error'], 'INVALID_CALL_TYPE');
  });

  // ── 8. book_session expert not found ──────────────────────────────────────
  test('8. book_session returns EXPERT_NOT_FOUND when expert missing', () async {
    final dispatcher = _dispatcher(
      getExpertPrice: (_) async => null,
      checkExistingAppointment: (_, __, ___) async => [],
    );

    final result = await dispatcher.dispatch('book_session', {
      'expert_id': 'nonexistent-expert',
      'appointment_date': '2024-04-01T10:00:00.000',
      'duration_minutes': 60,
      'call_type': 'video',
    });

    expect(result['error'], 'EXPERT_NOT_FOUND');
  });

  // ── 9. generate_monthly_report with mood entries ───────────────────────────
  test('9. generate_monthly_report returns correct structure with mood entries',
      () async {
    final entries = [
      {'mood_score': 7, 'emotion_factors': ['work', 'sleep']},
      {'mood_score': 6, 'emotion_factors': ['work', 'family']},
      {'mood_score': 8, 'emotion_factors': ['sleep', 'exercise']},
      {'mood_score': 9, 'emotion_factors': ['exercise', 'work']},
    ];

    final dispatcher = _dispatcher(
      getMoodEntries: (_, __, ___) async => entries,
      getUserAppointments: (_) async => [],
    );

    final result = await dispatcher.dispatch('generate_monthly_report', {
      'month': 4,
      'year': 2024,
    });

    expect(result['period'], '2024-04');
    expect(result['entries_count'], 4);
    expect(result['average_mood_score'], isA<double>());
    expect(result['trend'], isA<String>());
    expect(result['most_common_factors'], isA<List>());
    final factors = result['most_common_factors'] as List;
    expect(factors.length, lessThanOrEqualTo(3));
    expect(factors, contains('work')); // work appears 3 times (most common)
    expect(result['appointments_total'], isA<int>());
    expect(result['appointments_completed'], isA<int>());
    expect(result['appointments_upcoming'], isA<int>());
  });

  // ── 10. generate_monthly_report no entries ────────────────────────────────
  test('10. generate_monthly_report with no entries: 0.0 score, stable trend',
      () async {
    final dispatcher = _dispatcher(
      getMoodEntries: (_, __, ___) async => [],
      getUserAppointments: (_) async => [],
    );

    final result = await dispatcher.dispatch('generate_monthly_report', {
      'month': 4,
      'year': 2024,
    });

    expect(result['entries_count'], 0);
    expect(result['average_mood_score'], 0.0);
    expect(result['trend'], 'stable');
    expect(result['most_common_factors'], isEmpty);
  });

  // ── 11. generate_monthly_report leap year Feb 2024 ────────────────────────
  test('11. generate_monthly_report Feb 2024 date range includes Feb 29',
      () async {
    DateTime? capturedStart;
    DateTime? capturedEnd;

    final dispatcher = _dispatcher(
      getMoodEntries: (_, start, end) async {
        capturedStart = start;
        capturedEnd = end;
        return [];
      },
      getUserAppointments: (_) async => [],
    );

    await dispatcher.dispatch('generate_monthly_report', {
      'month': 2,
      'year': 2024,
    });

    expect(capturedStart, isNotNull);
    expect(capturedEnd, isNotNull);
    expect(capturedStart!.year, 2024);
    expect(capturedStart!.month, 2);
    expect(capturedStart!.day, 1);
    expect(capturedEnd!.month, 2);
    expect(capturedEnd!.day, 29); // Leap year — Feb has 29 days
  });

  // ── 12. Retry: first call throws, second succeeds ─────────────────────────
  test('12. retry: first call throws, second succeeds returns success result',
      () async {
    int attempts = 0;
    final dispatcher = _dispatcher(
      getAvailability: (_) async {
        attempts++;
        if (attempts == 1) throw Exception('transient error');
        return [_mondaySlot()];
      },
      generateTimeSlots: ({
        required startTime,
        required endTime,
        required int intervalMinutes,
      }) =>
          ['09:00'],
      getBookedTimeSlots: (_, __) async => [],
    );

    final result = await dispatcher.dispatch('check_expert_availability', {
      'expert_id': _expertId,
      'date': '2024-04-01',
    });

    // Should succeed on second attempt
    expect(result['available_slots'], isA<List>());
    expect(result.containsKey('retries_exhausted'), isFalse);
    expect(attempts, 2);
  });

  // ── 13. Retry exhausted: throws 3 times → retries_exhausted: true ─────────
  test('13. retry exhausted: throws 3 times returns retries_exhausted',
      () async {
    int attempts = 0;
    final dispatcher = _dispatcher(
      getAvailability: (_) async {
        attempts++;
        throw Exception('persistent error');
      },
    );

    final result = await dispatcher.dispatch('check_expert_availability', {
      'expert_id': _expertId,
      'date': '2024-04-01',
    });

    expect(result['retries_exhausted'], isTrue);
    expect(result['error'], isNotNull);
    expect(attempts, 3); // 1 initial + 2 retries
  });

  // ── 14. Unknown tool name → error map, does NOT throw ─────────────────────
  test('14. unknown tool name returns error map and does not throw', () async {
    final dispatcher = _dispatcher();

    final result = await dispatcher.dispatch('nonexistent_tool', {});

    expect(result['error'], isNotNull);
    expect(result.containsKey('retries_exhausted'), isTrue);
  });

  // ── 15. dispatch always returns (log is called) ───────────────────────────
  test('15. dispatch completes and returns a map for every call', () async {
    final dispatcher = _dispatcher();

    // Normal dispatch must return a map (not throw)
    final result = await dispatcher.dispatch('generate_monthly_report', {
      'month': 1,
      'year': 2024,
    });

    expect(result, isA<Map<String, Object?>>());
  });

  // ── 16. check_expert_availability: all slots booked → empty list ──────────
  test('16. check_expert_availability: all slots booked returns empty list',
      () async {
    final dispatcher = _dispatcher(
      getAvailability: (_) async => [_mondaySlot()],
      generateTimeSlots: ({
        required startTime,
        required endTime,
        required int intervalMinutes,
      }) =>
          ['09:00', '10:00'],
      getBookedTimeSlots: (_, __) async => ['09:00', '10:00'], // all booked
    );

    final result = await dispatcher.dispatch('check_expert_availability', {
      'expert_id': _expertId,
      'date': '2024-04-01',
    });

    final slots = result['available_slots'] as List;
    expect(slots, isEmpty);
    // Should NOT have a message key (that key is for "no work schedule" case)
    expect(result.containsKey('message'), isFalse);
  });

  // ── 17. book_session: user conflict → TIME_CONFLICT ───────────────────────
  test('17. book_session: user conflict returns TIME_CONFLICT', () async {
    final dispatcher = _dispatcher(
      createAppointment: (_) async =>
          throw Exception('Bạn đã có lịch hẹn trong khung giờ này'),
      checkExistingAppointment: (_, __, ___) async => [],
      getExpertPrice: (_) async => {'hourly_rate': 200000},
    );

    final result = await dispatcher.dispatch('book_session', {
      'expert_id': _expertId,
      'appointment_date': '2024-04-01T10:00:00.000',
      'duration_minutes': 60,
      'call_type': 'voice',
    });

    expect(result['error'], 'TIME_CONFLICT');
  });

  // ── 18. generate_monthly_report: month=2, year=2024 includes Feb 29 ───────
  test('18. generate_monthly_report: Feb 2024 date range is correct (leap year)',
      () async {
    DateTime? capturedStart;
    DateTime? capturedEnd;

    final dispatcher = _dispatcher(
      getMoodEntries: (_, start, end) async {
        capturedStart = start;
        capturedEnd = end;
        return [
          {'mood_score': 5, 'emotion_factors': []},
        ];
      },
      getUserAppointments: (_) async => [],
    );

    await dispatcher.dispatch('generate_monthly_report', {
      'month': 2,
      'year': 2024,
    });

    // Feb 29 must be inside [start, end]
    final feb29 = DateTime(2024, 2, 29);
    expect(feb29.isAfter(capturedStart!) || feb29 == capturedStart, isTrue);
    expect(feb29.isBefore(capturedEnd!) || feb29 == capturedEnd, isTrue);
  });
}
