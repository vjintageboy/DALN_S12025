import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/appointment.dart';

/// 📊 Analytics Dashboard
/// 
/// Shows expert's performance metrics:
/// - Total appointments by status (confirmed, completed, cancelled)
/// - Revenue/earnings from completed appointments
/// - Average rating (if rating system exists)
/// - Appointment trends (weekly/monthly)
/// - Cancellation rate
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;
  String? expertProfileId;

  // Time period filter
  String _selectedPeriod = 'All Time';
  final List<String> _periods = ['All Time', 'This Month', 'Last Month', 'This Year'];

  bool _isLoading = true;

  // Analytics data
  int _totalAppointments = 0;
  int _confirmedCount = 0;
  int _completedCount = 0;
  int _cancelledCount = 0;
  double _totalRevenue = 0.0;
  double _cancellationRate = 0.0;

  @override
  void initState() {
    super.initState();
    _loadExpertProfile();
  }

  Future<void> _loadExpertProfile() async {
    try {
      // Get expert profile ID from expertUsers collection
      final expertUserQuery = await FirebaseFirestore.instance
          .collection('expertUsers')
          .where('uid', isEqualTo: currentUid)
          .limit(1)
          .get();

      if (expertUserQuery.docs.isNotEmpty) {
        expertProfileId = expertUserQuery.docs.first.data()['expertId'];
        await _loadAnalytics();
      }
    } catch (e) {
      debugPrint('Error loading expert profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAnalytics() async {
    if (expertProfileId == null) return;

    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }
      
      // Get date range based on selected period
      final dateRange = _getDateRange();

      // Query appointments
      Query query = FirebaseFirestore.instance
          .collection('appointments')
          .where('expertId', isEqualTo: expertProfileId);

      // Add date filter if not "All Time"
      if (dateRange != null) {
        query = query
            .where('appointmentDate', isGreaterThanOrEqualTo: dateRange['start'])
            .where('appointmentDate', isLessThanOrEqualTo: dateRange['end']);
      }

      final snapshot = await query.get();
      
      if (!mounted) return;
      
      final appointments = snapshot.docs
          .map((doc) => Appointment.fromSnapshot(doc))
          .toList();

      // Calculate metrics
      _totalAppointments = appointments.length;
      _confirmedCount = appointments
          .where((apt) => apt.status == AppointmentStatus.confirmed)
          .length;
      _completedCount = appointments
          .where((apt) => apt.status == AppointmentStatus.completed)
          .length;
      _cancelledCount = appointments
          .where((apt) => apt.status == AppointmentStatus.cancelled)
          .length;

      // Calculate revenue from completed appointments
      _totalRevenue = appointments
          .where((apt) => apt.status == AppointmentStatus.completed)
          .fold(0.0, (total, apt) {
            // Calculate price based on duration and base price
            final hours = apt.durationMinutes / 60.0;
            final price = apt.expertBasePrice * hours;
            return total + price;
          });

      // Calculate cancellation rate
      _cancellationRate = _totalAppointments > 0
          ? (_cancelledCount / _totalAppointments) * 100
          : 0.0;

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, DateTime>? _getDateRange() {
    final now = DateTime.now();
    
    switch (_selectedPeriod) {
      case 'This Month':
        return {
          'start': DateTime(now.year, now.month, 1),
          'end': DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        };
      case 'Last Month':
        return {
          'start': DateTime(now.year, now.month - 1, 1),
          'end': DateTime(now.year, now.month, 0, 23, 59, 59),
        };
      case 'This Year':
        return {
          'start': DateTime(now.year, 1, 1),
          'end': DateTime(now.year, 12, 31, 23, 59, 59),
        };
      default:
        return null; // All Time
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Period filter
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: DropdownButton<String>(
              value: _selectedPeriod,
              dropdownColor: const Color(0xFF6C63FF),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              underline: Container(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: _periods.map((period) {
                return DropdownMenuItem(
                  value: period,
                  child: Text(period),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null && mounted) {
                  setState(() {
                    _selectedPeriod = value;
                  });
                  _loadAnalytics();
                }
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : expertProfileId == null
              ? const Center(child: Text('Expert profile not found'))
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header
                      _buildHeader(),
                      const SizedBox(height: 24),

                      // Summary Cards
                      _buildSummaryCards(),
                      const SizedBox(height: 24),

                      // Revenue Card
                      _buildRevenueCard(),
                      const SizedBox(height: 24),

                      // Status Breakdown
                      _buildStatusBreakdown(),
                      const SizedBox(height: 24),

                      // Cancellation Rate
                      _buildCancellationRate(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Color(0xFF6C63FF),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Performance Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedPeriod,
                        style: TextStyle(
                          color: Colors.grey.shade600,
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
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Total',
            _totalAppointments.toString(),
            Icons.event,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Completed',
            _completedCount.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard() {
    return Card(
      color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  color: const Color(0xFF6C63FF),
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Total Revenue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '\$${_totalRevenue.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'From $_completedCount completed appointment${_completedCount != 1 ? 's' : ''}',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appointments by Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildStatusRow(
              'Confirmed',
              _confirmedCount,
              Colors.blue,
              _totalAppointments,
            ),
            const Divider(height: 24),
            _buildStatusRow(
              'Completed',
              _completedCount,
              Colors.green,
              _totalAppointments,
            ),
            const Divider(height: 24),
            _buildStatusRow(
              'Cancelled',
              _cancelledCount,
              Colors.red,
              _totalAppointments,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(
    String label,
    int count,
    Color color,
    int total,
  ) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '(${percentage.toStringAsFixed(1)}%)',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCancellationRate() {
    Color rateColor;
    String rateLabel;

    if (_cancellationRate < 10) {
      rateColor = Colors.green;
      rateLabel = 'Excellent';
    } else if (_cancellationRate < 20) {
      rateColor = Colors.orange;
      rateLabel = 'Good';
    } else {
      rateColor = Colors.red;
      rateLabel = 'Needs Improvement';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cancellation Rate',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_cancellationRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: rateColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rateLabel,
                        style: TextStyle(
                          color: rateColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: rateColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _cancellationRate < 10
                            ? Icons.trending_down
                            : _cancellationRate < 20
                                ? Icons.trending_flat
                                : Icons.trending_up,
                        color: rateColor,
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_cancelledCount/$_totalAppointments',
                        style: TextStyle(
                          color: rateColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, 
                    size: 18, 
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lower cancellation rate leads to better reputation and more bookings',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
