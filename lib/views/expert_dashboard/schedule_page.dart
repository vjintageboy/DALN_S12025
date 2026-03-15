import 'package:flutter/material.dart';
import '../../models/availability.dart';
import '../../models/appointment.dart';
import '../../services/availability_service.dart';
import '../../services/supabase_service.dart';
import 'appointments_page.dart';

/// ✅ Schedule Management Page
///
/// Expert can set their weekly working hours using the new
/// `expert_availability` table (one row per enabled day).
///
/// ⚠️ IMPORTANT: Schedule Conflict Handling
/// When expert changes schedule, the system checks for conflicts with
/// existing confirmed appointments.
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final AvailabilityService _availabilityService = AvailabilityService();
  final _supabase = SupabaseService.instance.client;
  String? get currentUid => _supabase.auth.currentUser?.id;

  bool _isLoading = false;
  bool _isSaving = false;

  // --- DB day_of_week uses 0=Sun, 1=Mon … 6=Sat ---
  // We work with dart weekdays internally (1=Mon … 7=Sun) and convert
  // only at the DB boundary.

  /// Maps Dart weekday (1-7) → enabled flag
  final Map<int, bool> _dayEnabled = {
    DateTime.monday: false,
    DateTime.tuesday: false,
    DateTime.wednesday: false,
    DateTime.thursday: false,
    DateTime.friday: false,
    DateTime.saturday: false,
    DateTime.sunday: false,
  };

  /// Maps Dart weekday (1-7) → working hours for that day
  final Map<int, _TimeRange> _dayHours = {
    DateTime.monday: _TimeRange('09:00', '17:00'),
    DateTime.tuesday: _TimeRange('09:00', '17:00'),
    DateTime.wednesday: _TimeRange('09:00', '17:00'),
    DateTime.thursday: _TimeRange('09:00', '17:00'),
    DateTime.friday: _TimeRange('09:00', '17:00'),
    DateTime.saturday: _TimeRange('09:00', '17:00'),
    DateTime.sunday: _TimeRange('09:00', '17:00'),
  };

  // Break time is stored client-side only (no dedicated column in the new schema).
  // If needed, an expert can add a separate synthetic slot for break.
  // For now we keep the UI but note it has no DB persistence.
  _TimeRange? _breakTime;
  bool _hasBreakTime = false;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  // ── LOAD ─────────────────────────────────────────────────────────────────

  Future<void> _loadAvailability() async {
    if (currentUid == null) return;

    setState(() => _isLoading = true);
    try {
      final slots = await _availabilityService.getAvailability(currentUid!);

      if (mounted) {
        setState(() {
          // Reset all days to disabled first
          for (final k in _dayEnabled.keys) {
            _dayEnabled[k] = false;
          }

          for (final slot in slots) {
            final dartDay = slot.dartWeekday;
            _dayEnabled[dartDay] = true;
            _dayHours[dartDay] = _TimeRange(slot.startTime, slot.endTime);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading schedule: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── SAVE ──────────────────────────────────────────────────────────────────

  Future<void> _saveAvailability() async {
    if (currentUid == null) return;

    // Check for conflicts with existing appointments
    final conflicts = await _checkScheduleConflicts();
    if (conflicts.isNotEmpty && mounted) {
      final shouldContinue = await _showConflictWarningDialog(conflicts);
      if (!shouldContinue) return;
    }

    setState(() => _isSaving = true);
    try {
      // Build list of ExpertAvailability slots from UI state
      final slots = <ExpertAvailability>[];

      _dayEnabled.forEach((dartDay, isEnabled) {
        if (!isEnabled) return;
        final hours = _dayHours[dartDay]!;
        // Convert Dart weekday → DB day_of_week
        final dbDay = dartDay == DateTime.sunday ? 0 : dartDay; // Sun→0, Mon=1…Sat=6
        slots.add(ExpertAvailability(
          id: '',        // ignored on insert
          expertId: currentUid!,
          dayOfWeek: dbDay,
          startTime: hours.start,
          endTime: hours.end,
        ));
      });

      await _availabilityService.setAvailability(currentUid!, slots);

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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── CONFLICT CHECK ────────────────────────────────────────────────────────

  Future<List<Appointment>> _checkScheduleConflicts() async {
    try {
      if (currentUid == null) return [];

      debugPrint('🔍 Checking schedule conflicts...');

      final now = DateTime.now();
      final response = await _supabase
          .from('appointments')
          .select()
          .eq('expert_id', currentUid!)
          .eq('status', AppointmentStatus.confirmed.name)
          .gte('appointment_date', now.toIso8601String());

      debugPrint('Found ${response.length} confirmed appointments');
      final conflicted = <Appointment>[];

      for (final data in response) {
        final apt = Appointment.fromMap(data);
        final dartDay = apt.appointmentDate.weekday;
        final time = apt.appointmentDate;

        // Check 1: Day disabled
        if (!(_dayEnabled[dartDay] ?? false)) {
          conflicted.add(apt);
          debugPrint('⚠️ Conflict: Appointment on ${_getDayName(dartDay)} – day disabled');
          continue;
        }

        // Check 2: Outside new working hours
        final hours = _dayHours[dartDay]!;
        final workStart = _toDateTime(time, hours.start);
        final workEnd = _toDateTime(time, hours.end);

        if (time.isBefore(workStart) || time.isAfter(workEnd)) {
          conflicted.add(apt);
          continue;
        }

        // Check 3: During break time
        if (_hasBreakTime && _breakTime != null) {
          final bStart = _toDateTime(time, _breakTime!.start);
          final bEnd = _toDateTime(time, _breakTime!.end);
          final aptEnd = time.add(Duration(minutes: apt.durationMinutes));

          if (time.isBefore(bEnd) && aptEnd.isAfter(bStart)) {
            conflicted.add(apt);
          }
        }
      }

      debugPrint('✅ Conflict check: ${conflicted.length} conflicts found');
      return conflicted;
    } catch (e) {
      debugPrint('Error checking conflicts: $e');
      return [];
    }
  }

  // ── DIALOGS ───────────────────────────────────────────────────────────────

  Future<bool> _showConflictWarningDialog(List<Appointment> conflicts) async {
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
                    'Your new schedule conflicts with ${conflicts.length} existing '
                    'appointment${conflicts.length > 1 ? 's' : ''}:',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  ...conflicts.take(5).map((apt) {
                    final d = apt.appointmentDate;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.event, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${d.day}/${d.month}/${d.year} at '
                              '${d.hour.toString().padLeft(2, '0')}:'
                              '${d.minute.toString().padLeft(2, '0')} '
                              '(${apt.durationMinutes}min)',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (conflicts.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '… and ${conflicts.length - 5} more',
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
                                size: 18, color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Important',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'These appointments are still confirmed. You should:\n'
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AppointmentsPage()),
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
        ) ??
        false;
  }

  // ── TIME PICKER ───────────────────────────────────────────────────────────

  Future<void> _pickTime({
    required BuildContext context,
    required String initialTime,
    required void Function(String) onTimePicked,
  }) async {
    final parts = initialTime.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
    );
    if (picked != null) {
      onTimePicked(
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  String _getDayName(int dartWeekday) {
    const names = {
      DateTime.monday: 'Monday',
      DateTime.tuesday: 'Tuesday',
      DateTime.wednesday: 'Wednesday',
      DateTime.thursday: 'Thursday',
      DateTime.friday: 'Friday',
      DateTime.saturday: 'Saturday',
      DateTime.sunday: 'Sunday',
    };
    return names[dartWeekday] ?? '';
  }

  static DateTime _toDateTime(DateTime base, String hhmm) {
    final p = hhmm.split(':');
    return DateTime(base.year, base.month, base.day,
        int.parse(p[0]), int.parse(p[1]));
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Schedule',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6C63FF),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_month,
                        color: Color(0xFF6C63FF), size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Working Hours',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Set your availability for each day',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Changes to your schedule will be checked against existing appointments',
                    style:
                        TextStyle(fontSize: 13, color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Weekly schedule card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Weekly Schedule',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ..._dayEnabled.entries.map((entry) {
                    final dartDay = entry.key;
                    final isEnabled = entry.value;
                    final hours = _dayHours[dartDay]!;

                    return Column(
                      children: [
                        _buildDayRow(
                          dartDay: dartDay,
                          dayName: _getDayName(dartDay),
                          isEnabled: isEnabled,
                          hours: hours,
                        ),
                        if (dartDay != DateTime.sunday) const Divider(),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Break time card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Break Time (Optional)',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      Switch(
                        value: _hasBreakTime,
                        onChanged: (value) {
                          setState(() {
                            _hasBreakTime = value;
                            if (value && _breakTime == null) {
                              _breakTime = _TimeRange('12:00', '13:00');
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
                              initialTime: _breakTime!.start,
                              onTimePicked: (t) => setState(() {
                                _breakTime =
                                    _TimeRange(t, _breakTime!.end);
                              }),
                            ),
                            icon: const Icon(Icons.access_time),
                            label: Text(_breakTime!.start),
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
                              initialTime: _breakTime!.end,
                              onTimePicked: (t) => setState(() {
                                _breakTime =
                                    _TimeRange(_breakTime!.start, t);
                              }),
                            ),
                            icon: const Icon(Icons.access_time),
                            label: Text(_breakTime!.end),
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

          // Save button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAvailability,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save Schedule',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayRow({
    required int dartDay,
    required String dayName,
    required bool isEnabled,
    required _TimeRange hours,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            dayName,
            style: TextStyle(
              fontWeight:
                  isEnabled ? FontWeight.bold : FontWeight.normal,
              color: isEnabled ? Colors.black : Colors.grey,
            ),
          ),
        ),
        Switch(
          value: isEnabled,
          onChanged: (val) =>
              setState(() => _dayEnabled[dartDay] = val),
        ),
        const Spacer(),
        if (isEnabled)
          Row(
            children: [
              TextButton(
                onPressed: () => _pickTime(
                  context: context,
                  initialTime: hours.start,
                  onTimePicked: (t) => setState(() {
                    _dayHours[dartDay] = _TimeRange(t, hours.end);
                  }),
                ),
                child: Text(hours.start,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              const Text('-'),
              TextButton(
                onPressed: () => _pickTime(
                  context: context,
                  initialTime: hours.end,
                  onTimePicked: (t) => setState(() {
                    _dayHours[dartDay] = _TimeRange(hours.start, t);
                  }),
                ),
                child: Text(hours.end,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          )
        else
          const Text('Unavailable',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }
}

/// Simple immutable pair of HH:mm strings.
class _TimeRange {
  final String start;
  final String end;
  const _TimeRange(this.start, this.end);
}
