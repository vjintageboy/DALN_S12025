import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/availability.dart';
import '../../services/availability_service.dart';

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
