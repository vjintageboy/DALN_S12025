import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/expert_user.dart';
import '../../services/expert_user_service.dart';
import '../../services/firestore_service.dart';

class AdminExpertManagementPage extends StatefulWidget {
  const AdminExpertManagementPage({super.key});

  @override
  State<AdminExpertManagementPage> createState() => _AdminExpertManagementPageState();
}

class _AdminExpertManagementPageState extends State<AdminExpertManagementPage> {
  final _expertUserService = ExpertUserService();
  final _firestoreService = FirestoreService();
  
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Expert Management',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Status Filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'All',
                    isSelected: _selectedStatus == null,
                    onTap: () => setState(() => _selectedStatus = null),
                  ),
                  _buildFilterChip(
                    label: 'Pending',
                    isSelected: _selectedStatus == ExpertStatus.pending.name,
                    onTap: () => setState(() => _selectedStatus = ExpertStatus.pending.name),
                    color: Colors.orange,
                  ),
                  _buildFilterChip(
                    label: 'Approved',
                    isSelected: _selectedStatus == ExpertStatus.approved.name,
                    onTap: () => setState(() => _selectedStatus = ExpertStatus.approved.name),
                    color: Colors.green,
                  ),
                  _buildFilterChip(
                    label: 'Active',
                    isSelected: _selectedStatus == ExpertStatus.active.name,
                    onTap: () => setState(() => _selectedStatus = ExpertStatus.active.name),
                    color: Colors.blue,
                  ),
                  _buildFilterChip(
                    label: 'Rejected',
                    isSelected: _selectedStatus == ExpertStatus.rejected.name,
                    onTap: () => setState(() => _selectedStatus = ExpertStatus.rejected.name),
                    color: Colors.red,
                  ),
                  _buildFilterChip(
                    label: 'Suspended',
                    isSelected: _selectedStatus == ExpertStatus.suspended.name,
                    onTap: () => setState(() => _selectedStatus = ExpertStatus.suspended.name),
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // Expert List
          Expanded(
            child: StreamBuilder<List<ExpertUser>>(
              stream: _expertUserService.streamAllExpertUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4CAF50),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                var experts = snapshot.data ?? [];
                
                // Filter by status
                if (_selectedStatus != null) {
                  experts = experts.where((e) => e.status.name == _selectedStatus).toList();
                }

                if (experts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.medical_services_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedStatus == null
                              ? 'No experts yet'
                              : 'No experts with this status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: experts.length,
                  itemBuilder: (context, index) {
                    return _buildExpertCard(experts[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final baseColor = color ?? Colors.blue;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.grey.shade100,
        selectedColor: baseColor.withOpacity(0.1),
        checkmarkColor: baseColor,
        labelStyle: TextStyle(
          color: isSelected ? baseColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildExpertCard(ExpertUser expert) {
    Color statusColor;
    Color statusBgColor;
    Color statusTextColor;
    IconData statusIcon;
    
    switch (expert.status) {
      case ExpertStatus.pending:
        statusColor = Colors.orange;
        statusBgColor = Colors.orange.shade100;
        statusTextColor = Colors.orange.shade900;
        statusIcon = Icons.access_time;
        break;
      case ExpertStatus.approved:
        statusColor = Colors.green;
        statusBgColor = Colors.green.shade100;
        statusTextColor = Colors.green.shade900;
        statusIcon = Icons.check_circle;
        break;
      case ExpertStatus.active:
        statusColor = Colors.blue;
        statusBgColor = Colors.blue.shade100;
        statusTextColor = Colors.blue.shade900;
        statusIcon = Icons.verified;
        break;
      case ExpertStatus.rejected:
        statusColor = Colors.red;
        statusBgColor = Colors.red.shade100;
        statusTextColor = Colors.red.shade900;
        statusIcon = Icons.cancel;
        break;
      case ExpertStatus.suspended:
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.shade300;
        statusTextColor = Colors.grey.shade900;
        statusIcon = Icons.block;
        break;
      case ExpertStatus.inactive:
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.shade300;
        statusTextColor = Colors.grey.shade900;
        statusIcon = Icons.pause_circle;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: statusBgColor,
                  child: Icon(
                    Icons.medical_services,
                    color: statusTextColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expert.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        expert.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 14,
                        color: statusTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        expert.statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            
            // Credentials
            _buildInfoRow(
              Icons.school,
              'Education',
              expert.credentials.education ?? 'Not provided',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.badge,
              'License',
              expert.credentials.licenseNumber ?? 'Not provided',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.psychology,
              'Specialization',
              expert.credentials.specialization ?? 'Not provided',
            ),
            
            // Action Buttons
            if (expert.isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveExpert(expert),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectExpert(expert),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            if (expert.isApproved || expert.isActive) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _suspendExpert(expert),
                  icon: const Icon(Icons.block, size: 18),
                  label: const Text('Suspend Expert'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade700,
                    side: BorderSide(color: Colors.orange.shade700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            
            if (expert.isSuspended) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _unsuspendExpert(expert),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Unsuspend Expert'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _approveExpert(ExpertUser expert) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final isAdmin = await _firestoreService.isAdmin(currentUser.uid);
    if (!isAdmin) {
      _showMessage('Only admins can approve experts', Colors.red);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Expert'),
        content: Text('Approve ${expert.displayName} as an expert?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _expertUserService.approveExpert(
        expertUid: expert.uid,
        adminUid: currentUser.uid,
      );
      
      _showMessage('Expert approved successfully', Colors.green);
    } catch (e) {
      _showMessage('Error: $e', Colors.red);
    }
  }

  Future<void> _rejectExpert(ExpertUser expert) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final isAdmin = await _firestoreService.isAdmin(currentUser.uid);
    if (!isAdmin) {
      _showMessage('Only admins can reject experts', Colors.red);
      return;
    }

    final reasonController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Expert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject ${expert.displayName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result == null) return;

    try {
      await _expertUserService.rejectExpert(
        expertUid: expert.uid,
        adminUid: currentUser.uid,
        reason: result.isEmpty ? null : result,
      );
      
      _showMessage('Expert rejected', Colors.orange);
    } catch (e) {
      _showMessage('Error: $e', Colors.red);
    }
  }

  Future<void> _suspendExpert(ExpertUser expert) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final isAdmin = await _firestoreService.isAdmin(currentUser.uid);
    if (!isAdmin) {
      _showMessage('Only admins can suspend experts', Colors.red);
      return;
    }

    final reasonController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend Expert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Suspend ${expert.displayName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );

    if (result == null) return;

    try {
      await _expertUserService.suspendExpert(
        expertUid: expert.uid,
        adminUid: currentUser.uid,
        reason: result.isEmpty ? null : result,
      );
      
      _showMessage('Expert suspended', Colors.orange);
    } catch (e) {
      _showMessage('Error: $e', Colors.red);
    }
  }

  Future<void> _unsuspendExpert(ExpertUser expert) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final isAdmin = await _firestoreService.isAdmin(currentUser.uid);
    if (!isAdmin) {
      _showMessage('Only admins can unsuspend experts', Colors.red);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsuspend Expert'),
        content: Text('Unsuspend ${expert.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Unsuspend'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _expertUserService.unsuspendExpert(
        expertUid: expert.uid,
        adminUid: currentUser.uid,
      );
      
      _showMessage('Expert unsuspended', Colors.green);
    } catch (e) {
      _showMessage('Error: $e', Colors.red);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}
