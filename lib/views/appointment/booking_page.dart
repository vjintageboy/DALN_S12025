import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/localization_service.dart';
import '../../models/availability.dart';
import '../../models/expert.dart';
import '../../models/appointment.dart';
import '../../services/appointment_service.dart';
import '../../services/availability_service.dart';
import '../../services/supabase_service.dart';
import 'widgets/call_type_selector.dart';
import 'widgets/duration_selector.dart';
import 'mock_payment_page.dart';

class BookingPage extends StatefulWidget {
  final Expert? expert;
  final String? expertId;
  final String? chatRoomId;

  const BookingPage({super.key, this.expert, this.expertId, this.chatRoomId})
    : assert(
        expert != null || expertId != null,
        'Either expert or expertId must be provided',
      );

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final AppointmentService _appointmentService = AppointmentService();
  final AvailabilityService _availabilityService = AvailabilityService();
  final TextEditingController _notesController = TextEditingController();

  Expert? _expert;
  bool _isLoadingExpert = true;

  // Selections
  CallType _selectedCallType = CallType.video;
  int _selectedDuration = 60;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedTimeSlot;

  // Data
  /// Slots stored as "HH:mm-HH:mm" range strings
  List<String> _availableTimeSlots = [];
  bool _isLoadingSlots = false;

  /// Cached expert_availability rows – loaded once when expert is resolved.
  /// Used by the calendar enabledDayPredicate (synchronous).
  List<ExpertAvailability> _cachedAvailability = [];
  bool _availabilityLoaded = false;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _initData();
  }

  Future<void> _initData() async {
    if (widget.expert != null) {
      if (mounted) {
        setState(() {
          _expert = widget.expert;
          _isLoadingExpert = false;
        });
        // Pre-load availability for calendar
        await _preloadAvailability(widget.expert!.expertId);
      }
    } else if (widget.expertId != null) {
      await _loadExpertById(widget.expertId!);
    }
  }

  Future<void> _loadExpertById(String id) async {
    try {
      final loadedExpert = await Expert.getExpertById(id);

      if (mounted) {
        setState(() {
          _expert = loadedExpert;
          _isLoadingExpert = false;
        });
        // Pre-load availability for calendar
        if (loadedExpert != null) await _preloadAvailability(loadedExpert.expertId);
      }
    } catch (e) {
      debugPrint('Error loading expert: $e');
      if (mounted) {
        setState(() => _isLoadingExpert = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load expert info: $e')),
        );
      }
    }
  }

  /// Pre-fetches expert_availability rows so the calendar can mark days
  /// enabled/disabled synchronously (enabledDayPredicate must be sync).
  Future<void> _preloadAvailability(String expertId) async {
    try {
      final rows = await _availabilityService.getAvailability(expertId);
      debugPrint(
        '📅 [BookingPage] Pre-loaded ${rows.length} availability row(s) for $expertId',
      );
      for (final r in rows) {
        // Log both DB day_of_week (0=Sun) and Dart weekday (7=Sun)
        debugPrint(
          '   └─ db day_of_week=${r.dayOfWeek} (${r.dayName}) '
          'dart_weekday=${r.dartWeekday}  ${r.startTime}–${r.endTime}',
        );
      }
      if (mounted) {
        setState(() {
          _cachedAvailability = rows;
          _availabilityLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [BookingPage] Could not pre-load availability: $e');
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableSlots(DateTime date) async {
    if (_expert == null) return;

    // ── Debug log Step 1: selected date ─────────────────────────────────────
    final dbDayOfWeek = date.weekday == DateTime.sunday ? 0 : date.weekday;
    debugPrint(
      '🗓️  [Booking] Selected date: ${DateFormat('yyyy-MM-dd').format(date)}, '
      'dart weekday=${date.weekday}, db day_of_week=$dbDayOfWeek',
    );

    setState(() {
      _isLoadingSlots = true;
      _availableTimeSlots = [];
      _selectedTimeSlot = null;
    });

    try {
      // ── Step 2: Query expert_availability table ──────────────────────────
      final availabilityRows = _availabilityLoaded
          ? _cachedAvailability
          : await _availabilityService.getAvailability(_expert!.expertId);

      // Keep cache up-to-date
      if (!_availabilityLoaded && mounted) {
        setState(() {
          _cachedAvailability = availabilityRows;
          _availabilityLoaded = true;
        });
      }

      debugPrint(
        '📦 [Booking] DB availability rows (${availabilityRows.length}): '
        '${availabilityRows.map((r) => "day=${r.dayOfWeek}(${r.dayName}) "
            "${r.startTime}-${r.endTime}").join("; ")}',
      );

      // ── Step 3: Find ALL rows for this weekday (supports split shifts) ────
      // day_of_week mapping:
      //   DB convention:   0=Sun 1=Mon 2=Tue 3=Wed 4=Thu 5=Fri 6=Sat
      //   Dart convention: 7=Sun 1=Mon 2=Tue 3=Wed 4=Thu 5=Fri 6=Sat
      final dayRows = availabilityRows.slotsForWeekday(date.weekday);
      if (dayRows.isEmpty) {
        debugPrint(
          '⛔ [Booking] No availability rows for weekday=${date.weekday} '
          '(db day_of_week=$dbDayOfWeek) – no slots',
        );
        if (mounted) setState(() => _isLoadingSlots = false);
        return;
      }

      debugPrint(
        '📋 [Booking] Matched ${dayRows.length} row(s) for weekday=${date.weekday}: '
        '${dayRows.map((r) => "${r.startTime}-${r.endTime}").join(", ")}',
      );

      // ── Step 4: Generate slots for EACH row and merge ────────────────────
      // Each row may be a separate shift (e.g. morning + afternoon).
      final allSlots = <_Slot>[];
      for (final row in dayRows) {
        final rowSlots = _generateRangeSlots(
          startTime: row.startTime,
          endTime: row.endTime,
          intervalMinutes: _selectedDuration,
          date: date,
        );
        debugPrint(
          '🕐 [Booking] Row ${row.startTime}-${row.endTime} → '
          '${rowSlots.length} slot(s): ${rowSlots.map((s) => s.label).join(", ")}',
        );
        allSlots.addAll(rowSlots);
      }

      // Sort all merged slots chronologically
      allSlots.sort((a, b) => a.startDt.compareTo(b.startDt));

      debugPrint(
        '🕐 [Booking] Total generated: ${allSlots.length} slot(s) across '
        '${dayRows.length} row(s)',
      );

      // ── Step 5: Fetch booked slots from appointments table ───────────────
      final bookedRanges = await _getBookedRanges(
        expertId: _expert!.expertId,
        date: date,
      );
      debugPrint(
        '🔴 [Booking] Booked ranges (${bookedRanges.length}): '
        '${bookedRanges.join(", ")}',
      );

      // ── Step 6: Filter out booked + past slots ───────────────────────────
      final now = DateTime.now();
      final minAdvanceTime = now.add(const Duration(hours: 3));

      final finalSlots = <String>[];
      for (final slot in allSlots) {
        // Remove slots overlapping any booked range
        final isBooked = bookedRanges.any(
          (booked) => _rangesOverlap(slot, booked),
        );
        if (isBooked) continue;

        // Remove past slots when today is selected
        if (_isSameDay(date, now) && !slot.startDt.isAfter(minAdvanceTime)) {
          continue;
        }

        finalSlots.add(slot.label);
      }

      debugPrint(
        '✅ [Booking] Final available slots (${finalSlots.length}): '
        '${finalSlots.join(", ")}',
      );

      if (mounted) {
        setState(() {
          _availableTimeSlots = finalSlots;
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [Booking] Error loading slots: $e');
      if (mounted) setState(() => _isLoadingSlots = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading slots: $e')),
        );
      }
    }
  }

  // ─────────────── Slot helpers ────────────────────────────────────────────

  /// Generates slots as start-end range strings ("HH:mm-HH:mm") and keeps
  /// the parsed start DateTime for past-time filtering.
  List<_Slot> _generateRangeSlots({
    required String startTime,
    required String endTime,
    required int intervalMinutes,
    required DateTime date,
  }) {
    final slots = <_Slot>[];
    DateTime current = _parseHhmm(date, startTime);
    final end = _parseHhmm(date, endTime);

    while (current.isBefore(end)) {
      final slotEnd = current.add(Duration(minutes: intervalMinutes));
      // Don't emit a slot that extends past the end of working hours
      if (slotEnd.isAfter(end)) break;
      slots.add(_Slot(
        label:
            '${_fmt(current.hour, current.minute)}-'
            '${_fmt(slotEnd.hour, slotEnd.minute)}',
        startDt: current,
        endDt: slotEnd,
      ));
      current = slotEnd;
    }
    return slots;
  }

  /// Fetches booked appointment start-end ranges for [expertId] on [date].
  /// Includes all non-cancelled statuses (pending + confirmed).
  Future<List<String>> _getBookedRanges({
    required String expertId,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final response = await SupabaseService.instance.client
        .from('appointments')
        .select('appointment_date, duration_minutes, status')
        .eq('expert_id', expertId)
        .neq('status', 'cancelled')
        .gte('appointment_date', startOfDay.toIso8601String())
        .lte('appointment_date', endOfDay.toIso8601String());

    return (response as List).map((row) {
      final startDt = DateTime.parse(row['appointment_date'] as String);
      final duration = (row['duration_minutes'] as num?)?.toInt() ?? 60;
      final endDt = startDt.add(Duration(minutes: duration));
      return '${_fmt(startDt.hour, startDt.minute)}-'
          '${_fmt(endDt.hour, endDt.minute)}';
    }).toList();
  }

  /// Returns true if [slot] and [bookedRange] (both "HH:mm-HH:mm") overlap.
  bool _rangesOverlap(_Slot slot, String bookedRange) {
    final parts = bookedRange.split('-');
    if (parts.length < 2) return false;
    final bStart = _parseHhmm(slot.startDt, parts[0]);
    final bEnd = _parseHhmm(slot.startDt, parts[1]);
    return slot.startDt.isBefore(bEnd) && slot.endDt.isAfter(bStart);
  }

  static String _fmt(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  static DateTime _parseHhmm(DateTime date, String hhmm) {
    final p = hhmm.split(':');
    return DateTime(
        date.year, date.month, date.day, int.parse(p[0]), int.parse(p[1]));
  }

  DateTime _parseSlotTime(DateTime date, String slot) {
    // slot can be "HH:mm" or "HH:mm-HH:mm" – always use the start portion
    final start = slot.split('-').first;
    return _parseHhmm(date, start);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isDayAvailable(DateTime day) {
    if (_expert == null) return false;
    if (!_availabilityLoaded) {
      // Optimistic: allow all days while cache is loading
      return _expert!.isAvailable;
    }
    // Use cached rows for a precise per-day check
    return _cachedAvailability.isAvailableOnWeekday(day.weekday);
  }

  double get _currentPrice {
    if (_expert == null) return 0.0;
    return Appointment.calculatePrice(
      expertBasePrice: _expert!.pricePerSession,
      callType: _selectedCallType,
      duration: _selectedDuration,
    );
  }

  String _formatPrice(double price) {
    final intPrice = price.toInt();
    final formatter = intPrice.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '₫$formatter';
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (_expert == null) return;
    if (!_isDayAvailable(selectedDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_expert!.fullName} is not available on ${DateFormat('EEEE').format(selectedDay)}',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedTimeSlot = null; // Reset time slot
    });

    _loadAvailableSlots(selectedDay);
  }

  void _onDurationChanged(int duration) {
    setState(() {
      _selectedDuration = duration;
      _selectedTimeSlot = null; // Reset time slot
    });

    if (_selectedDay != null) {
      _loadAvailableSlots(_selectedDay!);
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedDay == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date and time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Use Supabase auth (not Firebase)
    final user = SupabaseService.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }

    if (_expert == null) return;

    // Parse selected date and time
    final appointmentDateTime = _parseSlotTime(
      _selectedDay!,
      _selectedTimeSlot!,
    );

    // Create appointment
    final appointment = Appointment(
      appointmentId: '', // Will be set by service
      userId: user.id,
      expertId: _expert!.expertId,
      expertName: _expert!.displayName,
      expertAvatarUrl: _expert!.avatarUrl,
      expertBasePrice: _expert!.pricePerSession, // ✅ Save expert base price
      callType: _selectedCallType,
      appointmentDate: appointmentDateTime,
      durationMinutes: _selectedDuration,
      userNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
      ),
    );

    try {
      // Create appointment (will throw if conflict exists)
      final newAppointmentId = await _appointmentService.createAppointment(
        appointment,
      );

      if (mounted && newAppointmentId != null) {
        Navigator.pop(context); // Close loading

        // Update appointment with the generated ID
        final appointmentWithId = appointment.copyWith(
          appointmentId: newAppointmentId,
        );

        // Success - navigate to mock payment
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MockPaymentPage(appointment: appointmentWithId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading

        // Show error message
        String errorMessage;
        if (e.toString().contains('already have an appointment')) {
          errorMessage =
              'You already have an appointment at this time. Please choose another time slot.';
        } else if (e.toString().contains('not available')) {
          errorMessage =
              'This expert is not available at the selected time. Please choose another time slot.';
        } else {
          errorMessage = 'Failed to book appointment. Please try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );

        // Refresh available slots
        if (_selectedDay != null) {
          _loadAvailableSlots(_selectedDay!);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingExpert) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_expert == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Expert not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.bookAppointment,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Expert Info Card
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: _expert!.avatarUrl != null
                        ? NetworkImage(_expert!.avatarUrl!)
                        : null,
                    child: _expert!.avatarUrl == null
                        ? Text(
                            _expert!.fullName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _expert!.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _expert!.specialization,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Call Type Selector
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: CallTypeSelector(
                selectedType: _selectedCallType,
                onChanged: (type) {
                  setState(() => _selectedCallType = type);
                },
              ),
            ),
            const SizedBox(height: 8),

            // Duration Selector
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: DurationSelector(
                selectedDuration: _selectedDuration,
                callType: _selectedCallType,
                expertBasePrice:
                    _expert!.pricePerSession, // ✅ Pass expert base price
                onChanged: _onDurationChanged,
              ),
            ),
            const SizedBox(height: 8),

            // Calendar
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.selectDate,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TableCalendar(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 14)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) =>
                        _selectedDay != null && _isSameDay(day, _selectedDay!),
                    onDaySelected: _onDaySelected,
                    calendarFormat: CalendarFormat.month,
                    enabledDayPredicate: (day) {
                      final now = DateTime.now();
                      final minDate = now.add(const Duration(hours: 3));
                      return day.isAfter(
                            minDate.subtract(const Duration(days: 1)),
                          ) &&
                          _isDayAvailable(day);
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      disabledTextStyle: TextStyle(color: Colors.grey.shade300),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Helper message when no date selected
            if (_selectedDay == null)
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.l10n.selectDateToView,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.chooseDateFromCalendar,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Time Slots
            if (_selectedDay != null) ...[
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Time Slots - ${DateFormat('EEE, MMM d').format(_selectedDay!)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingSlots)
                      const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4CAF50),
                        ),
                      )
                    else if (_availableTimeSlots.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No available slots for this day',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isDayAvailable(_selectedDay!)
                                    ? 'All slots are fully booked'
                                    : 'Expert is not available on ${DateFormat('EEEE').format(_selectedDay!)}s',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableTimeSlots.map((slot) {
                          final isSelected = _selectedTimeSlot == slot;
                          return InkWell(
                            onTap: () {
                              setState(() => _selectedTimeSlot = slot);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF4CAF50)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF4CAF50)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                slot,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade800,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Notes - Only show when date is selected
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.notesOptional,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Any notes for the expert?',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4CAF50),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Cancellation Policy
              Container(
                width: double.infinity,
                color: Colors.orange.shade50,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can cancel up to 4 hours before your appointment',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),

      // Bottom Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatPrice(_currentPrice),
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_selectedDay != null && _selectedTimeSlot != null)
                      ? _confirmBooking
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue to Payment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper value-object representing one generated time slot.
// ─────────────────────────────────────────────────────────────────────────────
class _Slot {
  /// Display label, e.g. "09:00-10:00"
  final String label;

  /// Parsed start DateTime (date portion taken from the selected calendar day)
  final DateTime startDt;

  /// Parsed end DateTime
  final DateTime endDt;

  const _Slot({
    required this.label,
    required this.startDt,
    required this.endDt,
  });
}
