import 'dart:developer' as developer;

import '../../models/appointment.dart';
import '../../models/availability.dart';

/// Routes Gemini FunctionCall names to actual service calls.
///
/// All service operations are injected as function callbacks so the dispatcher
/// remains fully testable without a live Supabase connection.
class ToolDispatcher {
  /// Returns all availability slots for an expert.
  final Future<List<ExpertAvailability>> Function(String expertId)
      getAvailability;

  /// Returns booked time slots ("HH:mm") for an expert on a given date.
  final Future<List<String>> Function(String expertId, DateTime date)
      getBookedTimeSlots;

  /// Generates all candidate time slots between start/end at the given interval.
  final List<String> Function({
    required String startTime,
    required String endTime,
    required int intervalMinutes,
  }) generateTimeSlots;

  /// Creates an appointment and returns its new ID, or throws on conflict.
  final Future<String?> Function(Appointment) createAppointment;

  /// Returns all appointments for a user.
  final Future<List<Appointment>> Function(String userId) getUserAppointments;

  /// Returns mood entries for a user within a date range.
  final Future<List<Map<String, dynamic>>> Function(
    String userId,
    DateTime start,
    DateTime end,
  ) getMoodEntries;

  /// Returns the expert row (needs `hourly_rate`), or null if not found.
  final Future<Map<String, dynamic>?> Function(String expertId) getExpertPrice;

  /// Returns existing non-cancelled appointments matching (userId, expertId, date).
  final Future<List<Map<String, dynamic>>?> Function(
    String userId,
    String expertId,
    DateTime date,
  ) checkExistingAppointment;

  /// The authenticated user's ID.
  final String userId;

  static const int _maxRetries = 2;

  // AppointmentService throws exceptions with these message patterns for conflicts.
  // If the service layer is refactored to use typed exceptions, update these constants.
  static const _expertConflictMsg = 'không rảnh';
  static const _userConflictMsg = 'đã có lịch';

  const ToolDispatcher({
    required this.getAvailability,
    required this.getBookedTimeSlots,
    required this.generateTimeSlots,
    required this.createAppointment,
    required this.getUserAppointments,
    required this.getMoodEntries,
    required this.getExpertPrice,
    required this.checkExistingAppointment,
    required this.userId,
  });

  // ---------------------------------------------------------------------------
  // Public entry point
  // ---------------------------------------------------------------------------

  Future<Map<String, Object?>> dispatch(
    String toolName,
    Map<String, Object?> args,
  ) async {
    final stopwatch = Stopwatch()..start();
    Map<String, Object?> result;
    int attempt = 0;

    while (true) {
      try {
        result = await _executeWithTimeout(toolName, args);
        break;
      } catch (e) {
        attempt++;
        if (attempt > _maxRetries) {
          result = {'error': e.toString(), 'retries_exhausted': true};
          break;
        }
        await Future.delayed(Duration(seconds: attempt)); // 1s, 2s
      }
    }

    stopwatch.stop();
    _log(toolName, args, result, stopwatch.elapsedMilliseconds);
    return result;
  }

  // ---------------------------------------------------------------------------
  // Timeout wrapper + routing
  // ---------------------------------------------------------------------------

  Future<Map<String, Object?>> _executeWithTimeout(
    String toolName,
    Map<String, Object?> args,
  ) {
    final Future<Map<String, Object?>> future = switch (toolName) {
      'check_expert_availability' => _checkAvailability(args),
      'book_session' => _bookSession(args),
      'generate_monthly_report' => _generateReport(args),
      _ => throw ArgumentError('Unknown tool: $toolName'),
    };
    return future.timeout(const Duration(seconds: 10));
  }

  // ---------------------------------------------------------------------------
  // Handler: check_expert_availability
  // ---------------------------------------------------------------------------

  Future<Map<String, Object?>> _checkAvailability(
    Map<String, Object?> args,
  ) async {
    final expertId = args['expert_id'] as String?;
    if (expertId == null || expertId.isEmpty) {
      return {'error': 'MISSING_ARG', 'arg': 'expert_id'};
    }
    final dateStr = args['date'] as String?;
    if (dateStr == null || dateStr.isEmpty) {
      return {'error': 'MISSING_ARG', 'arg': 'date'};
    }
    final durationMinutes = (args['duration_minutes'] as num?)?.toInt() ?? 60;

    final parsedDate = DateTime.parse(dateStr);

    final allSlots = await getAvailability(expertId);
    final matchingSlots = allSlots
        .where((slot) => slot.dartWeekday == parsedDate.weekday)
        .toList();

    if (matchingSlots.isEmpty) {
      return {
        'available_slots': <String>[],
        'message': 'Chuyên gia không có lịch làm việc ngày này',
        'expert_id': expertId,
        'date': dateStr,
        'duration_minutes': durationMinutes,
      };
    }

    // Generate all candidate slots from availability windows.
    final candidateSlots = <String>[];
    for (final slot in matchingSlots) {
      final generated = generateTimeSlots(
        startTime: slot.startTime,
        endTime: slot.endTime,
        intervalMinutes: durationMinutes,
      );
      candidateSlots.addAll(generated);
    }

    // Remove already-booked slots.
    final bookedSlots = await getBookedTimeSlots(expertId, parsedDate);
    final available = candidateSlots
        .where((s) => !bookedSlots.contains(s))
        .toList();

    return {
      'available_slots': available,
      'expert_id': expertId,
      'date': dateStr,
      'duration_minutes': durationMinutes,
    };
  }

  // ---------------------------------------------------------------------------
  // Handler: book_session (with idempotency)
  // ---------------------------------------------------------------------------

  Future<Map<String, Object?>> _bookSession(
    Map<String, Object?> args,
  ) async {
    final expertId = args['expert_id'] as String?;
    if (expertId == null || expertId.isEmpty) {
      return {'error': 'MISSING_ARG', 'arg': 'expert_id'};
    }
    final appointmentDateStr = args['appointment_date'] as String?;
    if (appointmentDateStr == null || appointmentDateStr.isEmpty) {
      return {'error': 'MISSING_ARG', 'arg': 'appointment_date'};
    }
    final durationMinutesRaw = args['duration_minutes'] as num?;
    if (durationMinutesRaw == null) {
      return {'error': 'MISSING_ARG', 'arg': 'duration_minutes'};
    }
    final durationMinutes = durationMinutesRaw.toInt();
    final callTypeStr = args['call_type'] as String?;
    if (callTypeStr == null || callTypeStr.isEmpty) {
      return {'error': 'MISSING_ARG', 'arg': 'call_type'};
    }
    final userNotes = args['user_notes'] as String?;

    // Validate duration
    if (durationMinutes != 30 && durationMinutes != 60) {
      return {
        'error': 'INVALID_DURATION',
        'message':
            'Thời lượng không hợp lệ. Chỉ chấp nhận 30 hoặc 60 phút.',
      };
    }

    // Validate call type
    if (callTypeStr != 'voice' && callTypeStr != 'video') {
      return {
        'error': 'INVALID_CALL_TYPE',
        'message': 'Loại cuộc gọi không hợp lệ. Chỉ chấp nhận voice hoặc video.',
      };
    }

    final appointmentDate = DateTime.parse(appointmentDateStr);

    // Idempotency check
    final existing =
        await checkExistingAppointment(userId, expertId, appointmentDate);
    if (existing != null && existing.isNotEmpty) {
      final first = existing.first;
      return {
        'success': true,
        'appointment_id': first['id']?.toString(),
        'status': first['status']?.toString(),
        'idempotent': true,
      };
    }

    // Fetch expert price
    final expertRow = await getExpertPrice(expertId);
    if (expertRow == null) {
      return {'error': 'EXPERT_NOT_FOUND'};
    }

    final expertBasePrice =
        double.tryParse(expertRow['hourly_rate']?.toString() ?? '') ?? 0.0;

    // Map call type
    final callType =
        callTypeStr == 'voice' ? CallType.voice : CallType.video;

    // Calculate price
    final price = Appointment.calculatePrice(
      expertBasePrice: expertBasePrice,
      callType: callType,
      duration: durationMinutes,
    );

    // Build appointment
    final appointment = Appointment(
      appointmentId: '',
      userId: userId,
      expertId: expertId,
      expertName: '',
      expertBasePrice: expertBasePrice,
      callType: callType,
      appointmentDate: appointmentDate,
      durationMinutes: durationMinutes,
      status: AppointmentStatus.pending,
      userNotes: userNotes,
    );

    try {
      final appointmentId = await createAppointment(appointment);
      return {
        'success': true,
        'appointment_id': appointmentId,
        'status': 'pending',
        'price': price,
      };
    } catch (e) {
      final message = e.toString();
      if (message.contains(_expertConflictMsg) || message.contains(_userConflictMsg)) {
        return {
          'error': 'TIME_CONFLICT',
          'message': 'Khung giờ này đã được đặt',
        };
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Handler: generate_monthly_report
  // ---------------------------------------------------------------------------

  Future<Map<String, Object?>> _generateReport(
    Map<String, Object?> args,
  ) async {
    final monthRaw = args['month'] as num?;
    if (monthRaw == null) {
      return {'error': 'MISSING_ARG', 'arg': 'month'};
    }
    final month = monthRaw.toInt();
    final yearRaw = args['year'] as num?;
    if (yearRaw == null) {
      return {'error': 'MISSING_ARG', 'arg': 'year'};
    }
    final year = yearRaw.toInt();

    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);

    // Query mood entries
    final entries = await getMoodEntries(userId, start, end);

    // Compute mood stats
    double averageMoodScore = 0.0;
    String trend = 'stable';

    if (entries.isNotEmpty) {
      final scores = entries
          .map((e) => (e['mood_score'] as num?)?.toDouble() ?? 0.0)
          .toList();

      final sum = scores.fold(0.0, (a, b) => a + b);
      averageMoodScore =
          double.parse((sum / scores.length).toStringAsFixed(1));

      // Trend: compare first half vs second half
      final mid = scores.length ~/ 2;
      final firstHalf = scores.sublist(0, mid);
      final secondHalf = scores.sublist(mid);

      if (firstHalf.isNotEmpty && secondHalf.isNotEmpty) {
        final firstAvg =
            firstHalf.fold(0.0, (a, b) => a + b) / firstHalf.length;
        final secondAvg =
            secondHalf.fold(0.0, (a, b) => a + b) / secondHalf.length;

        if (secondAvg > firstAvg + 0.2) {
          trend = 'improving';
        } else if (firstAvg > secondAvg + 0.2) {
          trend = 'declining';
        }
      }
    }

    // Most common factors (top 3)
    final factorCounts = <String, int>{};
    for (final entry in entries) {
      final rawFactors = entry['emotion_factors'];
      if (rawFactors is List) {
        for (final factor in rawFactors) {
          final key = factor.toString();
          factorCounts[key] = (factorCounts[key] ?? 0) + 1;
        }
      }
    }
    final sortedFactors = factorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final mostCommonFactors =
        sortedFactors.take(3).map((e) => e.key).toList();

    // Appointments
    final allAppointments = await getUserAppointments(userId);
    final monthAppointments = allAppointments.where((apt) {
      return !apt.appointmentDate.isBefore(start) &&
          !apt.appointmentDate.isAfter(end);
    }).toList();

    final now = DateTime.now();
    final appointmentsCompleted = monthAppointments
        .where((a) => a.status == AppointmentStatus.completed)
        .length;
    final appointmentsUpcoming = monthAppointments
        .where(
          (a) =>
              (a.status == AppointmentStatus.confirmed ||
                  a.status == AppointmentStatus.pending) &&
              a.appointmentDate.isAfter(now),
        )
        .length;

    return {
      'period': '$year-${month.toString().padLeft(2, '0')}',
      'entries_count': entries.length,
      'average_mood_score': averageMoodScore,
      'trend': trend,
      'most_common_factors': mostCommonFactors,
      'appointments_total': monthAppointments.length,
      'appointments_completed': appointmentsCompleted,
      'appointments_upcoming': appointmentsUpcoming,
    };
  }

  // ---------------------------------------------------------------------------
  // Logging
  // ---------------------------------------------------------------------------

  void _log(
    String toolName,
    Map<String, Object?> args,
    Map<String, Object?> result,
    int latencyMs,
  ) {
    final payload = {
      'tool': toolName,
      'user_id': userId,
      'args': args,
      'result': result,
      'latency_ms': latencyMs,
    }.toString();

    developer.log(
      payload,
      name: 'ToolDispatcher',
      error: result.containsKey('error') ? result['error'] : null,
    );
  }
}
