import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/appointment.dart';
import '../../services/appointment_service.dart';

class AppointmentDetailPage extends StatefulWidget {
  final Appointment appointment;

  const AppointmentDetailPage({
    super.key,
    required this.appointment,
  });

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AppointmentService _appointmentService = AppointmentService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userDoc = await _db.collection('users').doc(widget.appointment.userId).get();
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmAppointment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await _db
          .collection('appointments')
          .doc(widget.appointment.appointmentId)
          .update({
        'status': AppointmentStatus.confirmed.name,
        'confirmedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment confirmed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _completeAppointment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await _db
          .collection('appointments')
          .doc(widget.appointment.appointmentId)
          .update({
        'status': AppointmentStatus.completed.name,
        'completedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _cancelAppointment() async {
    final reason = await _showCancelDialog();
    if (reason == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _appointmentService.cancelAppointmentWithReason(
        widget.appointment.appointmentId,
        reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<String?> _showCancelDialog() async {
    final TextEditingController reasonController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for cancellation:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Reason for cancellation',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a reason')),
                );
                return;
              }
              Navigator.pop(context, reasonController.text.trim());
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'pending':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        icon = Icons.schedule;
        break;
      case 'confirmed':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        icon = Icons.check_circle_outline;
        break;
      case 'completed':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        icon = Icons.cancel_outlined;
        break;
      default:
        bgColor = Colors.grey.shade50;
        textColor = Colors.grey.shade700;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: const Color(0xFF6B4CE6),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Center(
                    child: _buildStatusBadge(widget.appointment.status.name),
                  ),
                  const SizedBox(height: 24),

                  // User Info Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Patient Information',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            Icons.account_circle,
                            'Name',
                            _userData?['displayName'] ?? 'Loading...',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.email,
                            'Email',
                            _userData?['email'] ?? 'Loading...',
                          ),
                          if (_userData?['phoneNumber'] != null) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.phone,
                              'Phone',
                              _userData!['phoneNumber'],
                            ),
                          ],
                          if (_userData?['gender'] != null) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.wc,
                              'Gender',
                              _userData!['gender'],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Appointment Details Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Appointment Details',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Date',
                            _formatDate(widget.appointment.appointmentDate),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.access_time,
                            'Time',
                            _formatTime(widget.appointment.appointmentDate),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.timer,
                            'Duration',
                            '${widget.appointment.durationMinutes} minutes',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.videocam,
                            'Call Type',
                            widget.appointment.callTypeLabel,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // User Notes (if any)
                  if (widget.appointment.userNotes != null &&
                      widget.appointment.userNotes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.note_alt, size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  'Patient Notes',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Text(
                              widget.appointment.userNotes!,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Cancellation Info (if cancelled)
                  if (widget.appointment.status == AppointmentStatus.cancelled) ...[
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      color: Colors.orange.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.orange.shade200,
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.cancel_outlined,
                                  size: 24,
                                  color: Colors.orange.shade700,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Cancellation Information',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade700,
                                      ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildInfoRow(
                              Icons.person_outline,
                              'Cancelled By',
                              widget.appointment.cancelledBy == 'expert' 
                                  ? 'Expert' 
                                  : 'Patient',
                            ),
                            if (widget.appointment.cancellationReason != null &&
                                widget.appointment.cancellationReason!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                Icons.description_outlined,
                                'Reason',
                                widget.appointment.cancellationReason!,
                              ),
                            ],
                            if (widget.appointment.cancelledAt != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                Icons.access_time,
                                'Cancelled At',
                                _formatDate(widget.appointment.cancelledAt!),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action Buttons
                  if (_isProcessing)
                    const Center(child: CircularProgressIndicator())
                  else
                    _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final status = widget.appointment.status;

    if (status == AppointmentStatus.pending) {
      // Pending: Show Confirm & Cancel
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _confirmAppointment,
              icon: const Icon(Icons.check_circle),
              label: const Text('Confirm Appointment'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _cancelAppointment,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel Appointment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
              ),
            ),
          ),
        ],
      );
    } else if (status == AppointmentStatus.confirmed) {
      // Confirmed: Show Complete & Cancel
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _completeAppointment,
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark as Completed'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _cancelAppointment,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel Appointment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
              ),
            ),
          ),
        ],
      );
    } else {
      // Completed or Cancelled: No actions available
      return Center(
        child: Text(
          status == AppointmentStatus.completed
              ? 'This appointment has been completed'
              : 'This appointment has been cancelled',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    final appointmentDay = DateTime(date.year, date.month, date.day);

    if (appointmentDay == today) {
      return 'Today';
    } else if (appointmentDay == tomorrow) {
      return 'Tomorrow';
    } else if (appointmentDay == yesterday) {
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
}
