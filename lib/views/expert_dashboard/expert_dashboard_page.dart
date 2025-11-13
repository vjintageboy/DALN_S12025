import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/expert_user.dart';
import '../../models/expert.dart';
import '../../models/appointment.dart';

class ExpertDashboardPage extends StatefulWidget {
  const ExpertDashboardPage({super.key});

  @override
  State<ExpertDashboardPage> createState() => _ExpertDashboardPageState();
}

class _ExpertDashboardPageState extends State<ExpertDashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  ExpertUser? _expertUser;
  Expert? _expertProfile;
  bool _isLoading = true;
  
  // Stats
  int _todayAppointments = 0;
  int _upcomingAppointments = 0;
  int _totalAppointments = 0;
  double _averageRating = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Load expert user data
      final expertUserDoc = await _db.collection('expertUsers').doc(user.uid).get();
      if (expertUserDoc.exists) {
        _expertUser = ExpertUser.fromSnapshot(expertUserDoc);
        
        // Load expert profile
        if (_expertUser?.expertId != null) {
          final expertDoc = await _db.collection('experts').doc(_expertUser!.expertId).get();
          if (expertDoc.exists) {
            _expertProfile = Expert.fromSnapshot(expertDoc);
          }
        }
      }

      // Load appointment stats
      await _loadAppointmentStats();
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Error loading dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAppointmentStats() async {
    if (_expertProfile == null) return;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get all appointments for this expert
      final appointmentsSnapshot = await _db
          .collection('appointments')
          .where('expertId', isEqualTo: _expertProfile!.expertId)
          .get();

      final appointments = appointmentsSnapshot.docs
          .map((doc) => Appointment.fromSnapshot(doc))
          .toList();

      // Calculate stats
      _totalAppointments = appointments.length;
      
      _todayAppointments = appointments.where((apt) {
        final aptDate = apt.appointmentDate;
        return aptDate.year == today.year &&
               aptDate.month == today.month &&
               aptDate.day == today.day &&
               apt.status != AppointmentStatus.cancelled;
      }).length;

      _upcomingAppointments = appointments.where((apt) {
        return apt.appointmentDate.isAfter(now) &&
               apt.status != AppointmentStatus.cancelled &&
               apt.status != AppointmentStatus.completed;
      }).length;

      // Use expert profile rating
      _averageRating = _expertProfile?.rating ?? 0.0;

    } catch (e) {
      print('❌ Error loading appointment stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
      );
    }

    if (_expertUser == null || !_expertUser!.canLogin) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.orange.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Expert Account Not Approved',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your expert application is ${_expertUser?.statusLabel ?? "pending"}. Please wait for admin approval.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey.shade50,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: const Color(0xFF4CAF50),
          child: CustomScrollView(
            slivers: [
              // App Bar
              _buildAppBar(),
              
              // Content
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    
                    // Stats Cards
                    _buildStatsCards(),
                    const SizedBox(height: 32),
                    
                    // Quick Actions
                    _buildQuickActions(),
                    const SizedBox(height: 32),
                    
                    // Today's Appointments
                    _buildTodayAppointments(),
                    const SizedBox(height: 32),
                    
                    // Upcoming Appointments Preview
                    _buildUpcomingPreview(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF4CAF50),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF4CAF50),
                const Color(0xFF4CAF50).withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        backgroundImage: _expertProfile?.avatarUrl != null
                            ? NetworkImage(_expertProfile!.avatarUrl!)
                            : null,
                        child: _expertProfile?.avatarUrl == null
                            ? Text(
                                _expertUser?.displayName.substring(0, 1).toUpperCase() ?? 'E',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4CAF50),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Expert Dashboard',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _expertProfile?.displayName ?? _expertUser?.displayName ?? 'Expert',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Today',
              '$_todayAppointments',
              'Appointments',
              Icons.calendar_today,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Upcoming',
              '$_upcomingAppointments',
              'Sessions',
              Icons.schedule,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Total',
              '$_totalAppointments',
              'Completed',
              Icons.check_circle,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'View All\nAppointments',
                  Icons.event_note,
                  Colors.blue,
                  () {
                    // TODO: Navigate to appointments page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Appointments page coming soon')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Manage\nSchedule',
                  Icons.calendar_month,
                  Colors.purple,
                  () {
                    // TODO: Navigate to schedule page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Schedule page coming soon')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'View\nAnalytics',
                  Icons.analytics,
                  Colors.teal,
                  () {
                    // TODO: Navigate to analytics page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Analytics page coming soon')),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayAppointments() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Schedule",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_todayAppointments > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_todayAppointments sessions',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _todayAppointments > 0
              ? _buildAppointmentsList(isToday: true)
              : _buildEmptyState(
                  'No appointments today',
                  'Enjoy your free time!',
                  Icons.event_available,
                ),
        ],
      ),
    );
  }

  Widget _buildUpcomingPreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Appointments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all appointments
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('View all coming soon')),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _upcomingAppointments > 0
              ? _buildAppointmentsList(isToday: false)
              : _buildEmptyState(
                  'No upcoming appointments',
                  'Your schedule is clear',
                  Icons.event_busy,
                ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList({required bool isToday}) {
    if (_expertProfile == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('appointments')
          .where('expertId', isEqualTo: _expertProfile!.expertId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
          );
        }

        final appointments = snapshot.data!.docs
            .map((doc) => Appointment.fromSnapshot(doc))
            .where((apt) {
              if (isToday) {
                final aptDate = apt.appointmentDate;
                return aptDate.year == today.year &&
                       aptDate.month == today.month &&
                       aptDate.day == today.day &&
                       apt.status != AppointmentStatus.cancelled;
              } else {
                return apt.appointmentDate.isAfter(now) &&
                       apt.status != AppointmentStatus.cancelled &&
                       apt.status != AppointmentStatus.completed;
              }
            })
            .toList()
          ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

        if (appointments.isEmpty) {
          return _buildEmptyState(
            isToday ? 'No appointments today' : 'No upcoming appointments',
            isToday ? 'Enjoy your free time!' : 'Your schedule is clear',
            Icons.event_available,
          );
        }

        return Column(
          children: appointments.take(isToday ? 10 : 3).map((appointment) {
            return _buildAppointmentCard(appointment);
          }).toList(),
        );
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient #${appointment.userId.substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment.userNotes ?? 'General consultation',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(appointment.status),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                '${_formatTime(appointment.appointmentDate)} • ${_formatDate(appointment.appointmentDate)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AppointmentStatus status) {
    Color color;
    String label;
    
    switch (status) {
      case AppointmentStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case AppointmentStatus.confirmed:
        color = Colors.blue;
        label = 'Confirmed';
        break;
      case AppointmentStatus.completed:
        color = Colors.green;
        label = 'Completed';
        break;
      case AppointmentStatus.cancelled:
        color = Colors.red;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color.alphaBlend(
            Colors.black.withOpacity(0.3),
            color,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
