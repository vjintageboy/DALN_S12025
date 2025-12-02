import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';
import 'momo_service.dart';
import 'chat_service.dart';
import 'notification_service.dart';

class AppointmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final MomoService _momoService = MomoService();
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
            'Chuyên gia không rảnh vào giờ này. Vui lòng chọn khung giờ khác.');
      }

      // Kiểm tra trùng giờ (người dùng)
      final hasUserConflict = await _checkUserTimeConflict(
        appointment.userId,
        appointment.appointmentDate,
        appointment.durationMinutes,
      );

      if (hasUserConflict) {
        throw Exception(
            'Bạn đã có lịch hẹn trong khung giờ này. Vui lòng chọn giờ khác.');
      }

      // Tạo document ID
      final docRef = _db.collection('appointments').doc();
      final newAppointment = appointment.copyWith(appointmentId: docRef.id);

      // Lưu vào DB
      await docRef.set(newAppointment.toMap());

      // Tạo phòng chat
      await _chatService.createChatRoom(
        appointmentId: docRef.id,
        userId: appointment.userId,
        expertId: appointment.expertId,
      );

      return docRef.id;
    } catch (e) {
      print('❌ Error creating appointment: $e');
      rethrow;
    }
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
        print('❌ Cannot update payment: appointmentId is empty');
        return;
      }

      await _db.collection('appointments').doc(appointmentId).update({
        'paymentId': paymentId,
        'paymentTransId': paymentTransId,
      });
    } catch (e) {
      print('❌ Error updating payment ID: $e');
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
      'expertId',
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
      'userId',
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
      final appointmentEnd =
          appointmentDate.add(Duration(minutes: durationMinutes));

      final startOfDay =
          DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day);
      final endOfDay = DateTime(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
        23,
        59,
        59,
      );

      final snapshot = await _db
          .collection('appointments')
          .where(fieldName, isEqualTo: fieldValue)
          .where('status', isEqualTo: AppointmentStatus.confirmed.name)
          .get();

      for (final doc in snapshot.docs) {
        final existing = Appointment.fromSnapshot(doc);

        if (existing.appointmentDate.isBefore(startOfDay) ||
            existing.appointmentDate.isAfter(endOfDay)) {
          continue;
        }

        final existingStart = existing.appointmentDate;
        final existingEnd = existingStart.add(
          Duration(minutes: existing.durationMinutes),
        );

        final overlaps = appointmentStart.isBefore(existingEnd) &&
            appointmentEnd.isAfter(existingStart);

        if (overlaps) return true;
      }

      return false;
    } catch (e) {
      print('❌ Error checking time conflict: $e');
      return false;
    }
  }

  // ===========================================================================
  //  GET USER APPOINTMENTS
  // ===========================================================================

  Future<List<Appointment>> getUserAppointments(String userId) async {
    try {
      final snapshot = await _db
          .collection('appointments')
          .where('userId', isEqualTo: userId)
          .get();

      final list = snapshot.docs
          .map((doc) => Appointment.fromSnapshot(doc))
          .toList();

      list.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

      return list;
    } catch (e) {
      print('❌ Error getting appointments: $e');
      return [];
    }
  }

  Stream<List<Appointment>> streamUserAppointments(String userId) {
    return _db
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.map((doc) => Appointment.fromSnapshot(doc)).toList();

      list.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

      return list;
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

      final docRef = _db.collection('appointments').doc(appointmentId);
      final doc = await docRef.get();
      if (!doc.exists) throw Exception('Appointment not found');

      final appointment = Appointment.fromSnapshot(doc);
      RefundStatus refundStatus = RefundStatus.none;

      String? paymentId = appointment.paymentId;
      String? transId = appointment.paymentTransId;

      print('ℹ️ Cancelling Appointment: ${appointment.appointmentId}');
      print('   Payment ID: $paymentId');
      print('   Trans ID: $transId');

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
          // Real MoMo Payment
          if (transId == null || transId == '0') {
            try {
              final query = await _momoService.checkStatus(paymentId);
              if (query != null && query['resultCode'] == 0) {
                final fetched = query['transId'];
                if (fetched != null && fetched is num && fetched > 0) {
                  transId = fetched.toString();
                  await docRef.update({'paymentTransId': transId});
                }
              }
            } catch (_) {}
          }

          if (transId != null && transId != '0') {
            final refund = await _momoService.refundPayment(
              orderId: paymentId,
              amount: appointment.price,
              transId: transId,
            );

            if (refund != null && refund['resultCode'] == 0) {
              refundStatus = RefundStatus.success;

              await _notificationService.sendNotification(
                userId: appointment.userId,
                title: 'Refund Successful',
                message:
                    'Your appointment with ${appointment.expertName} has been cancelled and refunded.',
                type: 'refund',
              );
            } else {
              refundStatus = RefundStatus.failed;

              await _notificationService.sendNotification(
                userId: appointment.userId,
                title: 'Refund Failed',
                message: 'Appointment cancelled but refund failed.',
                type: 'refund_error',
              );
            }
          } else {
            await _notificationService.sendNotification(
              userId: appointment.userId,
              title: 'Appointment Cancelled',
              message:
                  'Your appointment with ${appointment.expertName} has been cancelled.',
              type: 'cancellation',
            );
          }
        }
      } else {
        // No payment
        await _notificationService.sendNotification(
          userId: appointment.userId,
          title: 'Appointment Cancelled',
          message:
              'Your appointment with ${appointment.expertName} has been cancelled.',
          type: 'cancellation',
        );
      }

      await docRef.update({
        'status': AppointmentStatus.cancelled.name,
        'cancelledAt': Timestamp.now(),
        'cancelledBy': 'user',
        'refundStatus': refundStatus.name,
      });

      return refundStatus;
    } catch (e) {
      print('❌ Error cancelling appointment: $e');
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

      final docRef = _db.collection('appointments').doc(appointmentId);
      final doc = await docRef.get();
      if (!doc.exists) throw Exception('Appointment not found');

      final appointment = Appointment.fromSnapshot(doc);
      RefundStatus refundStatus = RefundStatus.none;

      String? paymentId = appointment.paymentId;
      String? transId = appointment.paymentTransId;

      print('ℹ️ Expert/Admin cancelling: ${appointment.appointmentId}');

      if (paymentId != null) {
        // Mock refund
        if (paymentId.startsWith('MOCK_')) {
          refundStatus = RefundStatus.success;

          await _notificationService.sendNotification(
            userId: appointment.userId,
            title: 'Appointment Cancelled & Refunded',
            message:
                'Expert ${appointment.expertName} cancelled the appointment. Reason: $reason. (Mock refund)',
            type: 'refund',
          );
        } else {
          // Real MoMo
          if (transId == null || transId == '0') {
            try {
              final status = await _momoService.checkStatus(paymentId);
              if (status != null && status['resultCode'] == 0) {
                final fetched = status['transId'];
                if (fetched != null && fetched is num && fetched > 0) {
                  transId = fetched.toString();
                  await docRef.update({'paymentTransId': transId});
                }
              }
            } catch (_) {}
          }

          if (transId != null && transId != '0') {
            final refund = await _momoService.refundPayment(
              orderId: paymentId,
              amount: appointment.price,
              transId: transId,
            );

            if (refund != null && refund['resultCode'] == 0) {
              refundStatus = RefundStatus.success;

              await _notificationService.sendNotification(
                userId: appointment.userId,
                title: 'Appointment Cancelled & Refunded',
                message:
                    'Expert ${appointment.expertName} cancelled the appointment. Reason: $reason.',
                type: 'refund',
              );
            } else {
              refundStatus = RefundStatus.failed;

              await _notificationService.sendNotification(
                userId: appointment.userId,
                title: 'Refund Failed',
                message:
                    'Expert cancelled the appointment but refund failed.',
                type: 'refund_error',
              );
            }
          } else {
            await _notificationService.sendNotification(
              userId: appointment.userId,
              title: 'Appointment Cancelled',
              message:
                  'Expert ${appointment.expertName} cancelled the appointment. Reason: $reason.',
              type: 'cancellation',
            );
          }
        }
      } else {
        await _notificationService.sendNotification(
          userId: appointment.userId,
          title: 'Appointment Cancelled',
          message:
              'Expert ${appointment.expertName} cancelled the appointment. Reason: $reason.',
          type: 'cancellation',
        );
      }

      await docRef.update({
        'status': AppointmentStatus.cancelled.name,
        'cancelledAt': Timestamp.now(),
        'cancellationReason': reason,
        'cancelledBy': 'expert',
        'refundStatus': refundStatus.name,
      });
    } catch (e) {
      print('❌ Error cancelling appointment: $e');
      rethrow;
    }
  }

// ===========================================================================
// GET APPOINTMENT BY ID
// ===========================================================================

  Future<Appointment?> getAppointmentById(String appointmentId) async {
  if (appointmentId.isEmpty) return null;
  try {
    final doc = await _db.collection('appointments').doc(appointmentId).get();
    if (!doc.exists) return null;
    return Appointment.fromSnapshot(doc);
  } catch (e) {
    print('❌ Error getting appointment by ID: $e');
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

      final snapshot = await _db
          .collection('appointments')
          .where('expertId', isEqualTo: expertId)
          .get();

      final slots = snapshot.docs
          .map((doc) => Appointment.fromSnapshot(doc))
          .where((apt) {
        if (apt.status != AppointmentStatus.confirmed) return false;

        return apt.appointmentDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
            apt.appointmentDate.isBefore(end.add(const Duration(seconds: 1)));
      }).map((apt) => _formatTimeSlot(apt.appointmentDate)).toList();

      return slots;
    } catch (e) {
      print('❌ Error getting booked slots: $e');
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
