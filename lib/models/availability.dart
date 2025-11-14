import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a time slot for expert availability
class TimeSlot {
  final String startTime; // Format: "HH:mm" (e.g., "09:00")
  final String endTime;   // Format: "HH:mm" (e.g., "17:00")

  TimeSlot({
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      startTime: map['startTime'] ?? '09:00',
      endTime: map['endTime'] ?? '17:00',
    );
  }

  @override
  String toString() => '$startTime - $endTime';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSlot &&
          runtimeType == other.runtimeType &&
          startTime == other.startTime &&
          endTime == other.endTime;

  @override
  int get hashCode => startTime.hashCode ^ endTime.hashCode;
}

/// Represents expert's availability schedule
class Availability {
  final String availabilityId;
  final String expertId;
  
  // Weekly schedule
  final bool monday;
  final bool tuesday;
  final bool wednesday;
  final bool thursday;
  final bool friday;
  final bool saturday;
  final bool sunday;
  
  // Working hours for each day
  final TimeSlot? mondayHours;
  final TimeSlot? tuesdayHours;
  final TimeSlot? wednesdayHours;
  final TimeSlot? thursdayHours;
  final TimeSlot? fridayHours;
  final TimeSlot? saturdayHours;
  final TimeSlot? sundayHours;
  
  // Break times (optional)
  final TimeSlot? breakTime;
  
  final DateTime updatedAt;

  Availability({
    required this.availabilityId,
    required this.expertId,
    this.monday = false,
    this.tuesday = false,
    this.wednesday = false,
    this.thursday = false,
    this.friday = false,
    this.saturday = false,
    this.sunday = false,
    this.mondayHours,
    this.tuesdayHours,
    this.wednesdayHours,
    this.thursdayHours,
    this.fridayHours,
    this.saturdayHours,
    this.sundayHours,
    this.breakTime,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  // Get time slot for a specific day
  TimeSlot? getTimeSlotForDay(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return monday ? mondayHours : null;
      case DateTime.tuesday:
        return tuesday ? tuesdayHours : null;
      case DateTime.wednesday:
        return wednesday ? wednesdayHours : null;
      case DateTime.thursday:
        return thursday ? thursdayHours : null;
      case DateTime.friday:
        return friday ? fridayHours : null;
      case DateTime.saturday:
        return saturday ? saturdayHours : null;
      case DateTime.sunday:
        return sunday ? sundayHours : null;
      default:
        return null;
    }
  }

  // Check if expert is available on a specific day
  bool isAvailableOnDay(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return monday;
      case DateTime.tuesday:
        return tuesday;
      case DateTime.wednesday:
        return wednesday;
      case DateTime.thursday:
        return thursday;
      case DateTime.friday:
        return friday;
      case DateTime.saturday:
        return saturday;
      case DateTime.sunday:
        return sunday;
      default:
        return false;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'availabilityId': availabilityId,
      'expertId': expertId,
      'monday': monday,
      'tuesday': tuesday,
      'wednesday': wednesday,
      'thursday': thursday,
      'friday': friday,
      'saturday': saturday,
      'sunday': sunday,
      'mondayHours': mondayHours?.toMap(),
      'tuesdayHours': tuesdayHours?.toMap(),
      'wednesdayHours': wednesdayHours?.toMap(),
      'thursdayHours': thursdayHours?.toMap(),
      'fridayHours': fridayHours?.toMap(),
      'saturdayHours': saturdayHours?.toMap(),
      'sundayHours': sundayHours?.toMap(),
      'breakTime': breakTime?.toMap(),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Availability.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Availability(
      availabilityId: doc.id,
      expertId: data['expertId'] ?? '',
      monday: data['monday'] ?? false,
      tuesday: data['tuesday'] ?? false,
      wednesday: data['wednesday'] ?? false,
      thursday: data['thursday'] ?? false,
      friday: data['friday'] ?? false,
      saturday: data['saturday'] ?? false,
      sunday: data['sunday'] ?? false,
      mondayHours: data['mondayHours'] != null
          ? TimeSlot.fromMap(data['mondayHours'])
          : null,
      tuesdayHours: data['tuesdayHours'] != null
          ? TimeSlot.fromMap(data['tuesdayHours'])
          : null,
      wednesdayHours: data['wednesdayHours'] != null
          ? TimeSlot.fromMap(data['wednesdayHours'])
          : null,
      thursdayHours: data['thursdayHours'] != null
          ? TimeSlot.fromMap(data['thursdayHours'])
          : null,
      fridayHours: data['fridayHours'] != null
          ? TimeSlot.fromMap(data['fridayHours'])
          : null,
      saturdayHours: data['saturdayHours'] != null
          ? TimeSlot.fromMap(data['saturdayHours'])
          : null,
      sundayHours: data['sundayHours'] != null
          ? TimeSlot.fromMap(data['sundayHours'])
          : null,
      breakTime: data['breakTime'] != null
          ? TimeSlot.fromMap(data['breakTime'])
          : null,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Availability copyWith({
    String? availabilityId,
    String? expertId,
    bool? monday,
    bool? tuesday,
    bool? wednesday,
    bool? thursday,
    bool? friday,
    bool? saturday,
    bool? sunday,
    TimeSlot? mondayHours,
    TimeSlot? tuesdayHours,
    TimeSlot? wednesdayHours,
    TimeSlot? thursdayHours,
    TimeSlot? fridayHours,
    TimeSlot? saturdayHours,
    TimeSlot? sundayHours,
    TimeSlot? breakTime,
    DateTime? updatedAt,
  }) {
    return Availability(
      availabilityId: availabilityId ?? this.availabilityId,
      expertId: expertId ?? this.expertId,
      monday: monday ?? this.monday,
      tuesday: tuesday ?? this.tuesday,
      wednesday: wednesday ?? this.wednesday,
      thursday: thursday ?? this.thursday,
      friday: friday ?? this.friday,
      saturday: saturday ?? this.saturday,
      sunday: sunday ?? this.sunday,
      mondayHours: mondayHours ?? this.mondayHours,
      tuesdayHours: tuesdayHours ?? this.tuesdayHours,
      wednesdayHours: wednesdayHours ?? this.wednesdayHours,
      thursdayHours: thursdayHours ?? this.thursdayHours,
      fridayHours: fridayHours ?? this.fridayHours,
      saturdayHours: saturdayHours ?? this.saturdayHours,
      sundayHours: sundayHours ?? this.sundayHours,
      breakTime: breakTime ?? this.breakTime,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
