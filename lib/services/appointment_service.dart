import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment.dart';
import 'chat_service.dart';
import 'notification_service.dart';
import 'supabase_service.dart';

class AppointmentService {
  final SupabaseClient _supabase = SupabaseService.instance.client;
  final NotificationService _notificationService = NotificationService();
  final ChatService _chatService = ChatService();

  // ===========================================================================
  //  CREATE APPOINTMENT
  // ===========================================================================

  Future<String?> createAppointment(Appointment appointment) async {
    try {
      // Kiểm tra trùng giờ (chuyên gia)
      final hasExpertConflict = await _checkExpertTimeConflict(
        appointment.expertId,
        appointment.appointmentDate,
        appointment.durationMinutes,
      );

      if (hasExpertConflict) {
        throw Exception(
          'Chuyên gia không rảnh vào giờ này. Vui lòng chọn khung giờ khác.',
        );
      }

      // Kiểm tra trùng giờ (người dùng)
      final hasUserConflict = await _checkUserTimeConflict(
        appointment.userId,
        appointment.appointmentDate,
        appointment.durationMinutes,
      );

      if (hasUserConflict) {
        throw Exception(
          'Bạn đã có lịch hẹn trong khung giờ này. Vui lòng chọn giờ khác.',
        );
      }

      // Save to Supabase
      final response = await _supabase
          .from('appointments')
          .insert({
            'user_id': appointment.userId,
            'expert_id': appointment.expertId,
            'appointment_date': appointment.appointmentDate.toIso8601String(),
            'duration_minutes': appointment.durationMinutes,
            'status': appointment.status.name,
            'user_notes': appointment.userNotes,
            'expert_base_price': appointment.expertBasePrice.round(),
            'call_type': _mapCallTypeToDb(appointment.callType),
          })
          .select()
          .single();

      final appointmentId = response['id'].toString();

      // Tạo phòng chat
      debugPrint(
        '💬 Creating Chat Room for User: ${appointment.userId} and Expert: ${appointment.expertId}',
      );
      await _chatService.createChatRoom(
        appointmentId: appointmentId,
        userId: appointment.userId,
        expertId: appointment.expertId,
      );
      debugPrint('✅ Chat Room Created/Updated');

      return appointmentId;
    } catch (e) {
      debugPrint('❌ Error creating appointment: $e');
      rethrow;
    }
  }

  String _mapCallTypeToDb(CallType callType) {
    // Schema currently uses call_type enum with default 'chat'.
    // Keep backward compatibility:
    // - voice -> chat
    // - video -> video
    return callType == CallType.voice ? 'chat' : 'video';
  }

  // ===========================================================================
  // UPDATE PAYMENT INFORMATION
  // ===========================================================================

  Future<void> updateAppointmentPaymentId(
    String appointmentId,
    String paymentId,
    String paymentTransId,
  ) async {
    try {
      if (appointmentId.isEmpty) {
        debugPrint('❌ Cannot update payment: appointmentId is empty');
        return;
      }

      await _supabase.from('appointments').update({
        'payment_id': paymentId,
        'payment_trans_id': paymentTransId,
      }).eq('id', appointmentId);
    } catch (e) {
      debugPrint('❌ Error updating payment ID: $e');
      rethrow;
    }
  }

  Future<void> confirmAppointment(String appointmentId) async {
    try {
      await _supabase.from('appointments').update({
        'status': AppointmentStatus.confirmed.name,
        'confirmed_at': DateTime.now().toIso8601String(),
      }).eq('id', appointmentId);
    } catch (e) {
      debugPrint('❌ Error confirming appointment: $e');
      rethrow;
    }
  }

  Future<void> completeAppointment(String appointmentId) async {
    try {
      await _supabase.from('appointments').update({
        'status': AppointmentStatus.completed.name,
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', appointmentId);
    } catch (e) {
      debugPrint('❌ Error completing appointment: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // CHECK TIME CONFLICT
  // ===========================================================================

  Future<bool> _checkExpertTimeConflict(
    String expertId,
    DateTime appointmentDate,
    int durationMinutes,
  ) async {
    return _checkTimeConflict(
      'expert_id',
      expertId,
      appointmentDate,
      durationMinutes,
    );
  }

  Future<bool> _checkUserTimeConflict(
    String userId,
    DateTime appointmentDate,
    int durationMinutes,
  ) async {
    return _checkTimeConflict(
      'user_id',
      userId,
      appointmentDate,
      durationMinutes,
    );
  }

  /// Kiểm tra trùng giờ chung
  Future<bool> _checkTimeConflict(
    String fieldName,
    String fieldValue,
    DateTime appointmentDate,
    int durationMinutes,
  ) async {
    try {
      final appointmentStart = appointmentDate;
      final appointmentEnd = appointmentDate.add(
        Duration(minutes: durationMinutes),
      );

      final response = await _supabase
          .from('appointments')
          .select()
          .eq(fieldName, fieldValue)
          .eq('status', AppointmentStatus.confirmed.name);

      for (final map in (response as List)) {
        final existing = Appointment.fromMap(map);

        final existingStart = existing.appointmentDate;
        final existingEnd = existingStart.add(
          Duration(minutes: existing.durationMinutes),
        );

        final overlaps =
            appointmentStart.isBefore(existingEnd) &&
            appointmentEnd.isAfter(existingStart);

        if (overlaps) return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking time conflict: $e');
      return false;
    }
  }

  // ===========================================================================
  //  GET USER APPOINTMENTS
  // ===========================================================================

  Future<List<Appointment>> getUserAppointments(String userId) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select('*, experts!expert_id(hourly_rate, bio, specialization, users!id(full_name, avatar_url))')
          .eq('user_id', userId)
          .order('appointment_date', ascending: false);

      return (response as List).map((m) => Appointment.fromMap(m)).toList();
    } catch (e) {
      debugPrint('❌ Error getting appointments: $e');
      return [];
    }
  }

  Stream<List<Appointment>> streamUserAppointments(String userId) {
    return _supabase
        .from('appointments')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('appointment_date', ascending: false)
        .asyncMap((data) async {
          if (data.isEmpty) return <Appointment>[];

          final expertIds = data
              .map((m) => m['expert_id'])
              .where((id) => id != null)
              .map((id) => id.toString())
              .toSet()
              .toList();

          final expertsData = expertIds.isEmpty
              ? <Map<String, dynamic>>[]
              : List<Map<String, dynamic>>.from(
                  await _supabase
                      .from('experts')
                      .select(
                        'id, hourly_rate, bio, specialization, users!id(full_name, avatar_url)',
                      )
                      .inFilter('id', expertIds),
                );

          final expertsMap = {
            for (final e in expertsData) e['id']?.toString(): e,
          };

          final enriched = data.map((m) {
            final row = Map<String, dynamic>.from(m);
            row['experts'] = expertsMap[row['expert_id']?.toString()];
            return Appointment.fromMap(row);
          }).toList();

          return enriched;
        });
  }

  // ===========================================================================
  // CANCEL APPOINTMENT (USER)
  // ===========================================================================

  Future<RefundStatus> cancelAppointment(String appointmentId) async {
    try {
      if (appointmentId.isEmpty) {
        throw Exception('Appointment ID is empty');
      }

      final response = await _supabase.from('appointments').select().eq('id', appointmentId).maybeSingle();
      if (response == null) throw Exception('Appointment not found');

      final appointment = Appointment.fromMap(response);
      RefundStatus refundStatus = RefundStatus.none;

      String? paymentId = appointment.paymentId;

      if (paymentId != null) {
        // Mock Payment
        if (paymentId.startsWith('MOCK_')) {
          refundStatus = RefundStatus.success;

          await _notificationService.sendNotification(
            userId: appointment.userId,
            title: 'Refund Successful',
            message:
                'Your appointment with ${appointment.expertName} has been cancelled and refunded successfully (Mock).',
            type: 'refund',
          );
        } else {
          // Real MoMo logic omitted for brevity/simplicity as per current implementation
          // ... 
        }
      }

      await _supabase.from('appointments').update({
        'status': AppointmentStatus.cancelled.name,
        'cancelled_at': DateTime.now().toIso8601String(),
        'cancelled_by': appointment.userId,
        'cancelled_role': 'user',
        'refund_status': refundStatus.name,
      }).eq('id', appointmentId);

      return refundStatus;
    } catch (e) {
      debugPrint('❌ Error cancelling appointment: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // CANCEL (ADMIN / EXPERT)
  // ===========================================================================

  Future<void> cancelAppointmentWithReason(
    String appointmentId,
    String reason,
  ) async {
    try {
      if (appointmentId.isEmpty) throw Exception('Appointment ID is empty');

      final response = await _supabase.from('appointments').select().eq('id', appointmentId).maybeSingle();
      if (response == null) throw Exception('Appointment not found');

      final appointment = Appointment.fromMap(response);
      RefundStatus refundStatus = RefundStatus.none;

      // Logic for refunding... (Mocked for now)
      if (appointment.paymentId?.startsWith('MOCK_') ?? false) {
        refundStatus = RefundStatus.success;
      }

      await _supabase.from('appointments').update({
        'status': AppointmentStatus.cancelled.name,
        'cancelled_at': DateTime.now().toIso8601String(),
        'cancellation_reason': reason,
        'cancelled_by': _supabase.auth.currentUser?.id ?? appointment.expertId,
        'cancelled_role': 'expert',
        'refund_status': refundStatus.name,
      }).eq('id', appointmentId);
      
      await _notificationService.sendNotification(
        userId: appointment.userId,
        title: 'Appointment Cancelled',
        message: 'Expert ${appointment.expertName} cancelled the appointment. Reason: $reason.',
        type: 'cancellation',
      );
    } catch (e) {
      debugPrint('❌ Error cancelling appointment: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // GET APPOINTMENT BY ID
  // ===========================================================================

  Future<Appointment?> getAppointmentById(String appointmentId) async {
    if (appointmentId.isEmpty) return null;
    try {
      final response = await _supabase
          .from('appointments')
          .select('*, experts!expert_id(hourly_rate, bio, specialization, users!id(full_name, avatar_url))')
          .eq('id', appointmentId)
          .maybeSingle();
          
      if (response == null) return null;
      return Appointment.fromMap(response);
    } catch (e) {
      debugPrint('❌ Error getting appointment by ID: $e');
      return null;
    }
  }

  // ===========================================================================
  // TIME SLOT HANDLING
  // ===========================================================================

  Future<List<String>> getBookedTimeSlots(
    String expertId,
    DateTime date,
  ) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final response = await _supabase
          .from('appointments')
          .select()
          .eq('expert_id', expertId)
          .eq('status', AppointmentStatus.confirmed.name)
          .gte('appointment_date', start.toIso8601String())
          .lte('appointment_date', end.toIso8601String());

      return (response as List)
          .map((m) => Appointment.fromMap(m))
          .map((apt) => _formatTimeSlot(apt.appointmentDate))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting booked slots: $e');
      return [];
    }
  }

  List<String> generateTimeSlots({
    required String startTime,
    required String endTime,
    required int intervalMinutes,
  }) {
    final List<String> slots = [];
    DateTime current = _parseTime(startTime);
    final DateTime end = _parseTime(endTime);

    while (current.isBefore(end)) {
      final hour = current.hour.toString().padLeft(2, '0');
      final minute = current.minute.toString().padLeft(2, '0');
      slots.add('$hour:$minute');
      current = current.add(Duration(minutes: intervalMinutes));
    }

    return slots;
  }

  String _formatTimeSlot(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  DateTime _parseTime(String time) {
    final parts = time.split(':');
    final now = DateTime.now();

    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}
