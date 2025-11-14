import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/availability.dart';
import '../../models/appointment.dart';
import '../../services/availability_service.dart';
import 'appointments_page.dart';

/// ✅ Schedule Management Page
/// 
/// Expert can set their weekly working hours:
/// - Enable/disable days (Mon-Sun)
/// - Set working hours for each day (start time - end time)
/// - Set optional break time (applies to all days)
/// 
/// ⚠️ IMPORTANT: Schedule Conflict Handling
/// When expert changes schedule, the system checks for conflicts with
/// existing confirmed appointments:
/// 
/// 1. Day disabled → Appointments on that day conflict
/// 2. Working hours changed → Appointments outside new hours conflict
/// 3. Break time added → Appointments during break conflict
/// 
/// If conflicts found:
/// - Show warning dialog with list of conflicted appointments
/// - Expert can:
///   a) Cancel changes
///   b) View appointments to reschedule/cancel them
///   c) Save anyway (appointments remain confirmed but outside working hours)
/// 
/// Note: System does NOT auto-cancel appointments. Expert must manually
/// handle conflicts by contacting patients and rescheduling.
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final AvailabilityService _availabilityService = AvailabilityService();
  final String expertId = FirebaseAuth.instance.currentUser!.uid;

  bool _isLoading = false;
  bool _isSaving = false;

  // Day availability
  final Map<int, bool> _dayAvailability = {
    DateTime.monday: false,
    DateTime.tuesday: false,
    DateTime.wednesday: false,
    DateTime.thursday: false,
    DateTime.friday: false,
    DateTime.saturday: false,
    DateTime.sunday: false,
  };

  // Time slots for each day
  final Map<int, TimeSlot> _dayTimeSlots = {
    DateTime.monday: TimeSlot(startTime: '09:00', endTime: '17:00'),
    DateTime.tuesday: TimeSlot(startTime: '09:00', endTime: '17:00'),
    DateTime.wednesday: TimeSlot(startTime: '09:00', endTime: '17:00'),
    DateTime.thursday: TimeSlot(startTime: '09:00', endTime: '17:00'),
    DateTime.friday: TimeSlot(startTime: '09:00', endTime: '17:00'),
    DateTime.saturday: TimeSlot(startTime: '09:00', endTime: '17:00'),
    DateTime.sunday: TimeSlot(startTime: '09:00', endTime: '17:00'),
  };

  // Break time
  TimeSlot? _breakTime;
  bool _hasBreakTime = false;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() => _isLoading = true);
    try {
      final availability = await _availabilityService.getAvailability(expertId);
      if (availability != null && mounted) {
        setState(() {
          // Load day availability
          _dayAvailability[DateTime.monday] = availability.monday;
          _dayAvailability[DateTime.tuesday] = availability.tuesday;
          _dayAvailability[DateTime.wednesday] = availability.wednesday;
          _dayAvailability[DateTime.thursday] = availability.thursday;
          _dayAvailability[DateTime.friday] = availability.friday;
          _dayAvailability[DateTime.saturday] = availability.saturday;
          _dayAvailability[DateTime.sunday] = availability.sunday;

          // Load time slots
          if (availability.mondayHours != null) {
            _dayTimeSlots[DateTime.monday] = availability.mondayHours!;
          }
          if (availability.tuesdayHours != null) {
            _dayTimeSlots[DateTime.tuesday] = availability.tuesdayHours!;
          }
          if (availability.wednesdayHours != null) {
            _dayTimeSlots[DateTime.wednesday] = availability.wednesdayHours!;
          }
          if (availability.thursdayHours != null) {
            _dayTimeSlots[DateTime.thursday] = availability.thursdayHours!;
          }
          if (availability.fridayHours != null) {
            _dayTimeSlots[DateTime.friday] = availability.fridayHours!;
          }
          if (availability.saturdayHours != null) {
            _dayTimeSlots[DateTime.saturday] = availability.saturdayHours!;
          }
          if (availability.sundayHours != null) {
            _dayTimeSlots[DateTime.sunday] = availability.sundayHours!;
          }

          // Load break time
          _breakTime = availability.breakTime;
          _hasBreakTime = availability.breakTime != null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading schedule: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveAvailability() async {
    // ✅ Check for conflicts with existing appointments
    final conflictedAppointments = await _checkScheduleConflicts();
    
    if (conflictedAppointments.isNotEmpty && mounted) {
      // Show warning dialog
      final shouldContinue = await _showConflictWarningDialog(
        conflictedAppointments,
      );
      
      if (!shouldContinue) {
        return; // User cancelled
      }
    }

    setState(() => _isSaving = true);
    try {
      final availability = Availability(
        availabilityId: '',
        expertId: expertId,
        monday: _dayAvailability[DateTime.monday]!,
        tuesday: _dayAvailability[DateTime.tuesday]!,
        wednesday: _dayAvailability[DateTime.wednesday]!,
        thursday: _dayAvailability[DateTime.thursday]!,
        friday: _dayAvailability[DateTime.friday]!,
        saturday: _dayAvailability[DateTime.saturday]!,
        sunday: _dayAvailability[DateTime.sunday]!,
        mondayHours: _dayAvailability[DateTime.monday]!
            ? _dayTimeSlots[DateTime.monday]
            : null,
        tuesdayHours: _dayAvailability[DateTime.tuesday]!
            ? _dayTimeSlots[DateTime.tuesday]
            : null,
        wednesdayHours: _dayAvailability[DateTime.wednesday]!
            ? _dayTimeSlots[DateTime.wednesday]
            : null,
        thursdayHours: _dayAvailability[DateTime.thursday]!
            ? _dayTimeSlots[DateTime.thursday]
            : null,
        fridayHours: _dayAvailability[DateTime.friday]!
            ? _dayTimeSlots[DateTime.friday]
            : null,
        saturdayHours: _dayAvailability[DateTime.saturday]!
            ? _dayTimeSlots[DateTime.saturday]
            : null,
        sundayHours: _dayAvailability[DateTime.sunday]!
            ? _dayTimeSlots[DateTime.sunday]
            : null,
        breakTime: _hasBreakTime ? _breakTime : null,
      );

      await _availabilityService.setAvailability(availability);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Schedule saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving schedule: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// ✅ Check if new schedule conflicts with existing confirmed appointments
  Future<List<Appointment>> _checkScheduleConflicts() async {
    try {
      // Get all upcoming confirmed appointments
      final now = DateTime.now();
      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('expertId', isEqualTo: expertId)
          .where('status', isEqualTo: AppointmentStatus.confirmed.name)
          .get();

      final conflictedAppointments = <Appointment>[];

      for (final doc in snapshot.docs) {
        final appointment = Appointment.fromSnapshot(doc);
        
        // Skip past appointments
        if (appointment.appointmentDate.isBefore(now)) {
          continue;
        }

        final weekday = appointment.appointmentDate.weekday;
        final appointmentTime = appointment.appointmentDate;

        // Check 1: Day is disabled
        if (!_dayAvailability[weekday]!) {
          conflictedAppointments.add(appointment);
          continue;
        }

        // Check 2: Outside working hours
        final timeSlot = _dayTimeSlots[weekday]!;
        final startParts = timeSlot.startTime.split(':');
        final endParts = timeSlot.endTime.split(':');
        
        final workStart = DateTime(
          appointmentTime.year,
          appointmentTime.month,
          appointmentTime.day,
          int.parse(startParts[0]),
          int.parse(startParts[1]),
        );
        
        final workEnd = DateTime(
          appointmentTime.year,
          appointmentTime.month,
          appointmentTime.day,
          int.parse(endParts[0]),
          int.parse(endParts[1]),
        );

        if (appointmentTime.isBefore(workStart) || 
            appointmentTime.isAfter(workEnd)) {
          conflictedAppointments.add(appointment);
          continue;
        }

        // Check 3: During break time
        if (_hasBreakTime && _breakTime != null) {
          final breakStartParts = _breakTime!.startTime.split(':');
          final breakEndParts = _breakTime!.endTime.split(':');
          
          final breakStart = DateTime(
            appointmentTime.year,
            appointmentTime.month,
            appointmentTime.day,
            int.parse(breakStartParts[0]),
            int.parse(breakStartParts[1]),
          );
          
          final breakEnd = DateTime(
            appointmentTime.year,
            appointmentTime.month,
            appointmentTime.day,
            int.parse(breakEndParts[0]),
            int.parse(breakEndParts[1]),
          );

          final appointmentEnd = appointmentTime.add(
            Duration(minutes: appointment.durationMinutes),
          );

          // Check if appointment overlaps with break time
          if (appointmentTime.isBefore(breakEnd) && 
              appointmentEnd.isAfter(breakStart)) {
            conflictedAppointments.add(appointment);
          }
        }
      }

      return conflictedAppointments;
    } catch (e) {
      print('Error checking schedule conflicts: $e');
      return [];
    }
  }

  /// ✅ Show warning dialog about conflicted appointments
  Future<bool> _showConflictWarningDialog(
    List<Appointment> conflicts,
  ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Schedule Conflict'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your new schedule conflicts with ${conflicts.length} existing appointment${conflicts.length > 1 ? 's' : ''}:',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ...conflicts.take(5).map((apt) {
                final date = apt.appointmentDate;
                final dateStr = '${date.day}/${date.month}/${date.year}';
                final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.event, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$dateStr at $timeStr (${apt.durationMinutes}min)',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              if (conflicts.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '... and ${conflicts.length - 5} more',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, 
                          size: 18, 
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Important',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'These appointments are still confirmed. You should:',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '• Contact patients to reschedule\n'
                      '• Or adjust your schedule to accommodate them',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
              // Navigate to appointments page to manage conflicts
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppointmentsPage(),
                ),
              );
            },
            child: const Text('View Appointments'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Anyway'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _pickTime({
    required BuildContext context,
    required String initialTime,
    required Function(String) onTimePicked,
  }) async {
    final parts = initialTime.split(':');
    final initialTimeOfDay = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTimeOfDay,
    );

    if (pickedTime != null) {
      final formattedTime =
          '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
      onTimePicked(formattedTime);
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Schedule',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_month,
                          color: Color(0xFF6C63FF),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Working Hours',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Set your availability for each day',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ⚠️ Info Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Changes to your schedule will be checked against existing appointments',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Weekly Schedule
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Schedule',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._dayAvailability.entries.map((entry) {
                    final weekday = entry.key;
                    final isAvailable = entry.value;
                    final timeSlot = _dayTimeSlots[weekday]!;

                    return Column(
                      children: [
                        _buildDaySchedule(
                          weekday: weekday,
                          dayName: _getDayName(weekday),
                          isAvailable: isAvailable,
                          timeSlot: timeSlot,
                        ),
                        if (weekday != DateTime.sunday) const Divider(),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Break Time
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Break Time (Optional)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Switch(
                        value: _hasBreakTime,
                        onChanged: (value) {
                          setState(() {
                            _hasBreakTime = value;
                            if (value && _breakTime == null) {
                              _breakTime = TimeSlot(
                                startTime: '12:00',
                                endTime: '13:00',
                              );
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  if (_hasBreakTime) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickTime(
                              context: context,
                              initialTime: _breakTime!.startTime,
                              onTimePicked: (time) {
                                setState(() {
                                  _breakTime = TimeSlot(
                                    startTime: time,
                                    endTime: _breakTime!.endTime,
                                  );
                                });
                              },
                            ),
                            icon: const Icon(Icons.access_time),
                            label: Text(_breakTime!.startTime),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('-'),
                        ),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickTime(
                              context: context,
                              initialTime: _breakTime!.endTime,
                              onTimePicked: (time) {
                                setState(() {
                                  _breakTime = TimeSlot(
                                    startTime: _breakTime!.startTime,
                                    endTime: time,
                                  );
                                });
                              },
                            ),
                            icon: const Icon(Icons.access_time),
                            label: Text(_breakTime!.endTime),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAvailability,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save Schedule',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySchedule({
    required int weekday,
    required String dayName,
    required bool isAvailable,
    required TimeSlot timeSlot,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  dayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Switch(
                value: isAvailable,
                onChanged: (value) {
                  setState(() {
                    _dayAvailability[weekday] = value;
                  });
                },
              ),
            ],
          ),
          if (isAvailable) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(
                      context: context,
                      initialTime: timeSlot.startTime,
                      onTimePicked: (time) {
                        setState(() {
                          _dayTimeSlots[weekday] = TimeSlot(
                            startTime: time,
                            endTime: timeSlot.endTime,
                          );
                        });
                      },
                    ),
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(timeSlot.startTime),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '-',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(
                      context: context,
                      initialTime: timeSlot.endTime,
                      onTimePicked: (time) {
                        setState(() {
                          _dayTimeSlots[weekday] = TimeSlot(
                            startTime: timeSlot.startTime,
                            endTime: time,
                          );
                        });
                      },
                    ),
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(timeSlot.endTime),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
