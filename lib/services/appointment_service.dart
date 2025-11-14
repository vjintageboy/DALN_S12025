import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';

class AppointmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create appointment
  Future<String?> createAppointment(Appointment appointment) async {
    try {
      // ✅ Check for expert time conflicts
      final hasExpertConflict = await _checkExpertTimeConflict(
        appointment.expertId,
        appointment.appointmentDate,
        appointment.durationMinutes,
      );

      if (hasExpertConflict) {
        throw Exception('This expert is not available at the selected time. Please choose another time slot.');
      }

      // ✅ Check for user time conflicts
      final hasUserConflict = await _checkUserTimeConflict(
        appointment.userId,
        appointment.appointmentDate,
        appointment.durationMinutes,
      );

      if (hasUserConflict) {
        throw Exception('You already have an appointment at this time. Please choose another time slot.');
      }

      final docRef = _db.collection('appointments').doc();
      final newAppointment = Appointment(
        appointmentId: docRef.id,
        userId: appointment.userId,
        expertId: appointment.expertId,
        expertName: appointment.expertName,
        expertAvatarUrl: appointment.expertAvatarUrl,
        expertBasePrice: appointment.expertBasePrice, // ✅ NEW
        callType: appointment.callType,
        appointmentDate: appointment.appointmentDate,
        durationMinutes: appointment.durationMinutes,
        status: AppointmentStatus.confirmed, // Auto-confirm
        userNotes: appointment.userNotes,
      );

      await docRef.set(newAppointment.toMap());
      return docRef.id;
    } catch (e) {
      print('❌ Error creating appointment: $e');
      rethrow; // Re-throw to show error message to user
    }
  }

  // ✅ Check if time slot conflicts with expert's existing appointments
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

  // ✅ Check if time slot conflicts with user's existing appointments
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

  // ✅ Generic time conflict checker
  Future<bool> _checkTimeConflict(
    String fieldName,
    String fieldValue,
    DateTime appointmentDate,
    int durationMinutes,
  ) async {
    try {
      final appointmentStart = appointmentDate;
      final appointmentEnd = appointmentDate.add(Duration(minutes: durationMinutes));

      // Get all confirmed appointments for this field on the same day
      final startOfDay = DateTime(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
      );
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

      // Check for overlaps
      for (final doc in snapshot.docs) {
        final existingAppt = Appointment.fromSnapshot(doc);
        
        // Skip if not on the same day
        if (existingAppt.appointmentDate.isBefore(startOfDay) ||
            existingAppt.appointmentDate.isAfter(endOfDay)) {
          continue;
        }

        final existingStart = existingAppt.appointmentDate;
        final existingEnd = existingAppt.appointmentDate.add(
          Duration(minutes: existingAppt.durationMinutes),
        );

        // Check if times overlap
        // Overlap happens if:
        // - New appointment starts before existing ends AND
        // - New appointment ends after existing starts
        final overlaps = appointmentStart.isBefore(existingEnd) &&
                        appointmentEnd.isAfter(existingStart);

        if (overlaps) {
          return true; // Conflict found
        }
      }

      return false; // No conflict
    } catch (e) {
      print('❌ Error checking time conflict: $e');
      return false; // Assume no conflict if error
    }
  }

  // Get user appointments
  Future<List<Appointment>> getUserAppointments(String userId) async {
    try {
      final snapshot = await _db
          .collection('appointments')
          .where('userId', isEqualTo: userId)
          .get();

      final appointments = snapshot.docs
          .map((doc) => Appointment.fromSnapshot(doc))
          .toList();
      
      // Sort trong code thay vì Firestore
      appointments.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
      
      return appointments;
    } catch (e) {
      print('❌ Error getting appointments: $e');
      return [];
    }
  }

  // Stream user appointments (real-time)
  Stream<List<Appointment>> streamUserAppointments(String userId) {
    return _db
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final appointments = snapshot.docs
              .map((doc) => Appointment.fromSnapshot(doc))
              .toList();
          
          // Sort trong code thay vì Firestore
          appointments.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
          
          return appointments;
        });
  }

  // Cancel appointment
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _db.collection('appointments').doc(appointmentId).update({
        'status': AppointmentStatus.cancelled.name,
        'cancelledAt': Timestamp.now(),
      });
    } catch (e) {
      print('❌ Error cancelling appointment: $e');
      rethrow;
    }
  }

  // Get booked time slots for expert on specific date
  Future<List<String>> getBookedTimeSlots(
    String expertId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // Simplified query - chỉ filter theo expertId
      final snapshot = await _db
          .collection('appointments')
          .where('expertId', isEqualTo: expertId)
          .get();

      // Filter trong code thay vì Firestore
      final bookedSlots = snapshot.docs
          .map((doc) => Appointment.fromSnapshot(doc))
          .where((apt) {
            // Filter: status = confirmed
            if (apt.status != AppointmentStatus.confirmed) return false;
            
            // Filter: date trong khoảng startOfDay -> endOfDay
            return apt.appointmentDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
                   apt.appointmentDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
          })
          .map((apt) => _formatTimeSlot(apt.appointmentDate))
          .toList();

      return bookedSlots;
    } catch (e) {
      print('❌ Error getting booked slots: $e');
      return [];
    }
  }

  String _formatTimeSlot(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Generate available time slots
  List<String> generateTimeSlots({
    required String startTime,
    required String endTime,
    required int intervalMinutes,
  }) {
    final slots = <String>[];
    
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    
    DateTime current = start;
    while (current.isBefore(end)) {
      final hour = current.hour.toString().padLeft(2, '0');
      final minute = current.minute.toString().padLeft(2, '0');
      slots.add('$hour:$minute');
      current = current.add(Duration(minutes: intervalMinutes));
    }
    
    return slots;
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
