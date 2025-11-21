import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import 'appointment_detail_page.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late TabController _tabController;
  String? _expertId;
  
  // Calendar view state
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Appointment>> _appointmentsByDate = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadExpertId();
  }

  Future<void> _loadExpertId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final expertDoc = await _db.collection('expertUsers').doc(user.uid).get();
      if (expertDoc.exists) {
        setState(() {
          _expertId = expertDoc.data()?['expertId'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error loading expertId: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        title: const Text(
          'Appointments',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
            Tab(text: 'Calendar'),
          ],
        ),
      ),
      body: _expertId == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentsList(null), // All
                _buildAppointmentsList('confirmed'), // Upcoming
                _buildAppointmentsList('completed'), // Completed
                _buildAppointmentsList('cancelled'), // Cancelled
                _buildCalendarView(), // Calendar
              ],
            ),
    );
  }

  Widget _buildAppointmentsList(String? statusFilter) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getAppointmentsStream(statusFilter),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
          );
        }

        final appointments = snapshot.data!.docs
            .map((doc) {
              try {
                return Appointment.fromSnapshot(doc);
              } catch (e) {
                debugPrint('Error parsing appointment: $e');
                return null;
              }
            })
            .whereType<Appointment>()
            .toList();

        // Sort by date (newest first)
        appointments.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

        if (appointments.isEmpty) {
          return _buildEmptyState(statusFilter);
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild to refresh stream
          },
          color: const Color(0xFF4CAF50),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              return _buildAppointmentCard(appointments[index]);
            },
          ),
        );
      },
    );
  }

  Stream<QuerySnapshot> _getAppointmentsStream(String? statusFilter) {
    Query query = _db
        .collection('appointments')
        .where('expertId', isEqualTo: _expertId);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.snapshots();
  }

  Widget _buildEmptyState(String? statusFilter) {
    String message;
    IconData icon;

    switch (statusFilter) {
      case 'confirmed':
        message = 'No upcoming appointments';
        icon = Icons.event_available;
        break;
      case 'completed':
        message = 'No completed appointments';
        icon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        message = 'No cancelled appointments';
        icon = Icons.cancel_outlined;
        break;
      default:
        message = 'No appointments yet';
        icon = Icons.calendar_today;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your appointments will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppointmentDetailPage(
                  appointment: appointment,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Date & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(appointment.appointmentDate),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    _buildStatusBadge(appointment.status.name),
                  ],
                ),
                const SizedBox(height: 12),

                // Time & Duration
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatTime(appointment.appointmentDate)} (${appointment.durationMinutes} min)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Call Type
                Text(
                  appointment.callTypeLabel,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),

                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 12),

                // User info
                FutureBuilder<DocumentSnapshot>(
                  future: _db.collection('users').doc(appointment.userId).get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Text(
                        'Loading user...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      );
                    }

                    final userData = snapshot.data?.data() as Map<String, dynamic>?;
                    final userName = userData?['displayName'] ?? 'Unknown User';
                    final userEmail = userData?['email'] ?? '';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
                              child: Text(
                                userName.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    userEmail,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                // User Notes (if any)
                if (appointment.userNotes != null && appointment.userNotes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.notes,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            appointment.userNotes!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Cancellation Info (if cancelled)
                if (appointment.status == AppointmentStatus.cancelled) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.cancel_outlined,
                              size: 16,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Cancelled by ${appointment.cancelledBy ?? 'user'}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                        if (appointment.cancellationReason != null &&
                            appointment.cancellationReason!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Reason: ${appointment.cancellationReason}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'pending':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        label = 'Pending';
        break;
      case 'confirmed':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        label = 'Confirmed';
        break;
      case 'completed':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        label = 'Completed';
        break;
      case 'cancelled':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        label = 'Cancelled';
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDay = DateTime(date.year, date.month, date.day);

    if (appointmentDay == today) {
      return 'Today';
    } else if (appointmentDay == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (appointmentDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // ============= CALENDAR VIEW METHODS =============

  Widget _buildCalendarView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('appointments')
          .where('expertId', isEqualTo: _expertId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
          );
        }

        // Parse appointments
        final appointments = snapshot.data!.docs
            .map((doc) {
              try {
                return Appointment.fromSnapshot(doc);
              } catch (e) {
                debugPrint('Error parsing appointment: $e');
                return null;
              }
            })
            .whereType<Appointment>()
            .toList();

        // Group appointments by date
        _appointmentsByDate = {};
        for (final apt in appointments) {
          final date = DateTime(
            apt.appointmentDate.year,
            apt.appointmentDate.month,
            apt.appointmentDate.day,
          );
          if (_appointmentsByDate[date] == null) {
            _appointmentsByDate[date] = [];
          }
          _appointmentsByDate[date]!.add(apt);
        }

        return CustomScrollView(
          slivers: [
            // Calendar
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.all(16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TableCalendar(
                    firstDay: DateTime.now().subtract(const Duration(days: 365)),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) {
                      return _selectedDay != null && _isSameDay(day, _selectedDay!);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarFormat: CalendarFormat.month,
                    eventLoader: (day) {
                      final date = DateTime(day.year, day.month, day.day);
                      return _appointmentsByDate[date] ?? [];
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: Color(0xFF2196F3),
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 3,
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isEmpty) return null;
                        
                        return Positioned(
                          bottom: 1,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF2196F3),
                              shape: BoxShape.circle,
                            ),
                            width: 6,
                            height: 6,
                            child: Center(
                              child: Text(
                                '${events.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 0,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Legend
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      label: 'Today',
                    ),
                    const SizedBox(width: 16),
                    _buildLegendItem(
                      color: const Color(0xFF4CAF50),
                      label: 'Selected',
                    ),
                    const SizedBox(width: 16),
                    _buildLegendItem(
                      color: const Color(0xFF2196F3),
                      label: 'Has Appointments',
                      isCircle: true,
                      size: 6,
                    ),
                  ],
                ),
              ),
            ),

            // Divider
            SliverToBoxAdapter(
              child: Divider(
                height: 32,
                thickness: 1,
                color: Colors.grey.shade200,
                indent: 16,
                endIndent: 16,
              ),
            ),

            // Selected day header (if day is selected)
            if (_selectedDay != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event,
                        color: Colors.grey.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Appointments on ${DateFormat('EEE, MMM d, yyyy').format(_selectedDay!)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Appointments list or empty state
            if (_selectedDay == null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select a date to view appointments',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildSelectedDayAppointmentsSlivers(),
          ],
        );
      },
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    bool isCircle = true,
    double size = 12,
  }) {
    return Row(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDayAppointmentsSlivers() {
    final date = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );
    final dayAppointments = _appointmentsByDate[date] ?? [];

    // Sort by time
    dayAppointments.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

    if (dayAppointments.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_available,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No appointments on this day',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _buildAppointmentCard(dayAppointments[index]);
          },
          childCount: dayAppointments.length,
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
