import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/availability.dart';

class AvailabilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get expert's availability schedule
  Future<Availability?> getAvailability(String expertId) async {
    try {
      final querySnapshot = await _firestore
          .collection('availability')
          .where('expertId', isEqualTo: expertId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return Availability.fromSnapshot(querySnapshot.docs.first);
    } catch (e) {
      print('Error getting availability: $e');
      rethrow;
    }
  }

  /// Stream expert's availability (for real-time updates)
  Stream<Availability?> streamAvailability(String expertId) {
    return _firestore
        .collection('availability')
        .where('expertId', isEqualTo: expertId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return Availability.fromSnapshot(snapshot.docs.first);
    });
  }

  /// Create or update expert's availability
  Future<void> setAvailability(Availability availability) async {
    try {
      // Check if availability already exists
      final existing = await getAvailability(availability.expertId);

      if (existing != null) {
        // Update existing
        await _firestore
            .collection('availability')
            .doc(existing.availabilityId)
            .update(availability.toMap());
      } else {
        // Create new
        final docRef = _firestore.collection('availability').doc();
        final newAvailability = availability.copyWith(
          availabilityId: docRef.id,
          updatedAt: DateTime.now(),
        );
        await docRef.set(newAvailability.toMap());
      }

      // ✅ Sync summary to experts collection (for easy filtering)
      await _syncToExpertsCollection(availability);
    } catch (e) {
      print('Error setting availability: $e');
      rethrow;
    }
  }

  /// Sync availability summary to experts collection
  /// This allows filtering experts by available days without querying availability collection
  Future<void> _syncToExpertsCollection(Availability availability) async {
    try {
      // Get expertId (profile ID) from expertUsers collection
      final expertUserDoc = await _firestore
          .collection('expertUsers')
          .doc(availability.expertId) // expertId is actually uid
          .get();

      if (!expertUserDoc.exists) {
        print('ExpertUser not found, skipping sync to experts collection');
        return;
      }

      final expertProfileId = expertUserDoc.data()?['expertId'] as String?;
      if (expertProfileId == null) {
        print('Expert profile ID not found, skipping sync');
        return;
      }

      // Build availability array (days enabled)
      final availableDays = <String>[];
      if (availability.monday) availableDays.add('Monday');
      if (availability.tuesday) availableDays.add('Tuesday');
      if (availability.wednesday) availableDays.add('Wednesday');
      if (availability.thursday) availableDays.add('Thursday');
      if (availability.friday) availableDays.add('Friday');
      if (availability.saturday) availableDays.add('Saturday');
      if (availability.sunday) availableDays.add('Sunday');

      // Update experts collection
      await _firestore
          .collection('experts')
          .doc(expertProfileId)
          .update({
        'availability': availableDays,
        'isAvailable': availableDays.isNotEmpty,
      });

      print('✅ Synced availability to experts collection');
    } catch (e) {
      print('⚠️ Error syncing to experts collection: $e');
      // Don't rethrow - this is optional sync, shouldn't fail main operation
    }
  }

  /// Update specific day availability
  Future<void> updateDayAvailability({
    required String expertId,
    required int weekday,
    required bool isAvailable,
    TimeSlot? timeSlot,
  }) async {
    try {
      final availability = await getAvailability(expertId);
      if (availability == null) {
        throw Exception('Availability not found for expert');
      }

      Map<String, dynamic> updates = {
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      // Update day availability and time slot
      switch (weekday) {
        case DateTime.monday:
          updates['monday'] = isAvailable;
          updates['mondayHours'] = timeSlot?.toMap();
          break;
        case DateTime.tuesday:
          updates['tuesday'] = isAvailable;
          updates['tuesdayHours'] = timeSlot?.toMap();
          break;
        case DateTime.wednesday:
          updates['wednesday'] = isAvailable;
          updates['wednesdayHours'] = timeSlot?.toMap();
          break;
        case DateTime.thursday:
          updates['thursday'] = isAvailable;
          updates['thursdayHours'] = timeSlot?.toMap();
          break;
        case DateTime.friday:
          updates['friday'] = isAvailable;
          updates['fridayHours'] = timeSlot?.toMap();
          break;
        case DateTime.saturday:
          updates['saturday'] = isAvailable;
          updates['saturdayHours'] = timeSlot?.toMap();
          break;
        case DateTime.sunday:
          updates['sunday'] = isAvailable;
          updates['sundayHours'] = timeSlot?.toMap();
          break;
      }

      await _firestore
          .collection('availability')
          .doc(availability.availabilityId)
          .update(updates);
    } catch (e) {
      print('Error updating day availability: $e');
      rethrow;
    }
  }

  /// Update break time
  Future<void> updateBreakTime({
    required String expertId,
    TimeSlot? breakTime,
  }) async {
    try {
      final availability = await getAvailability(expertId);
      if (availability == null) {
        throw Exception('Availability not found for expert');
      }

      await _firestore
          .collection('availability')
          .doc(availability.availabilityId)
          .update({
        'breakTime': breakTime?.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error updating break time: $e');
      rethrow;
    }
  }

  /// Check if expert is available at specific date/time
  Future<bool> isAvailableAt({
    required String expertId,
    required DateTime dateTime,
  }) async {
    try {
      final availability = await getAvailability(expertId);
      if (availability == null) {
        return false;
      }

      // Check if available on this day of week
      if (!availability.isAvailableOnDay(dateTime.weekday)) {
        return false;
      }

      // Get working hours for this day
      final timeSlot = availability.getTimeSlotForDay(dateTime.weekday);
      if (timeSlot == null) {
        return false;
      }

      // Parse time slot
      final startParts = timeSlot.startTime.split(':');
      final endParts = timeSlot.endTime.split(':');
      
      final startTime = DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        int.parse(startParts[0]),
        int.parse(startParts[1]),
      );
      
      final endTime = DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
      );

      // Check if requested time is within working hours
      if (dateTime.isBefore(startTime) || dateTime.isAfter(endTime)) {
        return false;
      }

      // Check if it's during break time
      if (availability.breakTime != null) {
        final breakStartParts = availability.breakTime!.startTime.split(':');
        final breakEndParts = availability.breakTime!.endTime.split(':');
        
        final breakStart = DateTime(
          dateTime.year,
          dateTime.month,
          dateTime.day,
          int.parse(breakStartParts[0]),
          int.parse(breakStartParts[1]),
        );
        
        final breakEnd = DateTime(
          dateTime.year,
          dateTime.month,
          dateTime.day,
          int.parse(breakEndParts[0]),
          int.parse(breakEndParts[1]),
        );

        // If appointment time overlaps with break time, not available
        if (dateTime.isAfter(breakStart) && dateTime.isBefore(breakEnd)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Error checking availability: $e');
      return false;
    }
  }

  /// Get available days of week for expert
  Future<List<int>> getAvailableDays(String expertId) async {
    try {
      final availability = await getAvailability(expertId);
      if (availability == null) {
        return [];
      }

      final availableDays = <int>[];
      if (availability.monday) availableDays.add(DateTime.monday);
      if (availability.tuesday) availableDays.add(DateTime.tuesday);
      if (availability.wednesday) availableDays.add(DateTime.wednesday);
      if (availability.thursday) availableDays.add(DateTime.thursday);
      if (availability.friday) availableDays.add(DateTime.friday);
      if (availability.saturday) availableDays.add(DateTime.saturday);
      if (availability.sunday) availableDays.add(DateTime.sunday);

      return availableDays;
    } catch (e) {
      print('Error getting available days: $e');
      return [];
    }
  }
}
