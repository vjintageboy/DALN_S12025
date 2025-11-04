import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_user.dart';

// User stats model
class UserStats {
  final int moodEntries;
  final int currentStreak;
  final int meditationsDone;
  final DateTime? lastLogin;

  UserStats({
    required this.moodEntries,
    required this.currentStreak,
    required this.meditationsDone,
    this.lastLogin,
  });
}

/// User Management Page - Admin page to manage all users
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<AppUser> _users = [];
  List<AppUser> _filteredUsers = [];
  Map<String, UserStats> _userStats = {}; // Cache user stats
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedRole; // null = all, 'admin', 'user'

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      final users = snapshot.docs.map((doc) {
        return AppUser.fromFirestore(doc.data(), doc.id);
      }).toList();

      // Load stats for all users
      await _loadUserStats(users);

      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  Future<void> _loadUserStats(List<AppUser> users) async {
    final Map<String, UserStats> stats = {};
    
    try {
      // Batch query 1: Get ALL mood entries at once
      final allMoodEntries = await FirebaseFirestore.instance
          .collection('moodEntries')
          .get();
      
      // Group mood entries by userId
      final moodCountByUser = <String, int>{};
      for (var doc in allMoodEntries.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        
        if (userId != null && userId.isNotEmpty) {
          moodCountByUser[userId] = (moodCountByUser[userId] ?? 0) + 1;
        }
      }
      
      // Batch query 2: Get ALL streaks at once
      final allStreaks = await FirebaseFirestore.instance
          .collection('streaks')
          .get();
      
      final streakByUser = <String, int>{};
      for (var doc in allStreaks.docs) {
        final data = doc.data();
        streakByUser[doc.id] = (data['currentStreak'] ?? 0) as int;
      }
      
      // Batch query 3: Get ALL profiles at once
      final allProfiles = await FirebaseFirestore.instance
          .collection('profiles')
          .get();
      
      final meditationsByUser = <String, int>{};
      for (var doc in allProfiles.docs) {
        final data = doc.data();
        meditationsByUser[doc.id] = (data['totalMeditationsCompleted'] ?? 0) as int;
      }
      
      // Build stats for each user from cached data
      for (var user in users) {
        stats[user.id] = UserStats(
          moodEntries: moodCountByUser[user.id] ?? 0,
          currentStreak: streakByUser[user.id] ?? 0,
          meditationsDone: meditationsByUser[user.id] ?? 0,
          lastLogin: user.lastLoginAt,
        );
      }
    } catch (e) {
      // If error, use default stats for all users
      for (var user in users) {
        stats[user.id] = UserStats(
          moodEntries: 0,
          currentStreak: 0,
          meditationsDone: 0,
          lastLogin: user.lastLoginAt,
        );
      }
    }
    
    setState(() {
      _userStats = stats;
    });
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _users.where((user) {
        // Search filter
        final matchesSearch = _searchQuery.isEmpty ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase());

        // Role filter
        final matchesRole = _selectedRole == null || user.role.value == _selectedRole;

        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  Future<void> _changeUserRole(AppUser user) async {
    final newRole = user.role == UserRole.admin ? UserRole.user : UserRole.admin;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User Role'),
        content: Text(
          'Change ${user.email} role from "${user.role.value.toUpperCase()}" to "${newRole.value.toUpperCase()}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .update({'role': newRole.value});

      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User role changed to ${newRole.value.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(AppUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${user.email}?\n\nThis will delete:\n• User account\n• Profile data\n• Mood entries\n• Streak data\n\nThis action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Delete user data from Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.id).delete();
      await FirebaseFirestore.instance.collection('profiles').doc(user.id).delete();
      
      // Delete user's mood entries
      final moodEntries = await FirebaseFirestore.instance
          .collection('moodEntries')
          .where('userId', isEqualTo: user.id)
          .get();
      for (var doc in moodEntries.docs) {
        await doc.reference.delete();
      }
      
      // Delete user's streak
      await FirebaseFirestore.instance.collection('streaks').doc(user.id).delete();

      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _filterUsers();
                  },
                ),
                const SizedBox(height: 12),

                // Role Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All Users',
                        isSelected: _selectedRole == null,
                        onTap: () {
                          setState(() => _selectedRole = null);
                          _filterUsers();
                        },
                      ),
                      _buildFilterChip(
                        label: 'Admin',
                        isSelected: _selectedRole == 'admin',
                        onTap: () {
                          setState(() => _selectedRole = 'admin');
                          _filterUsers();
                        },
                      ),
                      _buildFilterChip(
                        label: 'User',
                        isSelected: _selectedRole == 'user',
                        onTap: () {
                          setState(() => _selectedRole = 'user');
                          _filterUsers();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // User Count
          if (!_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredUsers.length} user${_filteredUsers.length != 1 ? 's' : ''} found',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),

          // User List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            return _buildUserCard(_filteredUsers[index]);
                          },
                        ),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.grey.shade100,
        selectedColor: Colors.blue.shade50,
        checkmarkColor: Colors.blue.shade700,
        labelStyle: TextStyle(
          color: isSelected ? Colors.blue.shade700 : Colors.black87,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildUserCard(AppUser user) {
    final isAdmin = user.role == UserRole.admin;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isAdmin
                      ? Colors.purple.shade100
                      : Colors.blue.shade100,
                  child: Icon(
                    isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: isAdmin ? Colors.purple.shade700 : Colors.blue.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Email and Role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isAdmin
                              ? Colors.purple.shade50
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          user.role.value.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isAdmin
                                ? Colors.purple.shade700
                                : Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action Buttons
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'change_role') {
                      _changeUserRole(user);
                    } else if (value == 'delete') {
                      _deleteUser(user);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'change_role',
                      child: Row(
                        children: [
                          Icon(
                            Icons.swap_horiz,
                            size: 20,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Change to ${isAdmin ? "User" : "Admin"}',
                            style: TextStyle(color: Colors.blue.shade700),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Delete User',
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            
            // User Stats Row 1
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.calendar_today,
                    'Joined',
                    _formatDate(user.createdAt),
                  ),
                ),
                Expanded(
                  child: _buildStatusBadge(user),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // User Stats Row 2 - Activity Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.mood,
                    'Moods',
                    '${_userStats[user.id]?.moodEntries ?? 0}',
                    color: Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.local_fire_department,
                    'Streak',
                    '${_userStats[user.id]?.currentStreak ?? 0}d',
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.spa,
                    'Sessions',
                    '${_userStats[user.id]?.meditationsDone ?? 0}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, {Color? color}) {
    final iconColor = color ?? Colors.grey.shade600;
    final textColor = color ?? Colors.black87;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(AppUser user) {
    final now = DateTime.now();
    final daysSinceLogin = user.lastLoginAt != null 
        ? now.difference(user.lastLoginAt!).inDays 
        : now.difference(user.createdAt).inDays;
    
    // Active: login trong 7 ngày
    // Warning: login 7-30 ngày trước
    // Inactive: không login > 30 ngày
    
    String status;
    Color color;
    IconData icon;
    
    if (daysSinceLogin <= 7) {
      status = 'Active';
      color = Colors.green;
      icon = Icons.verified_user;
    } else if (daysSinceLogin <= 30) {
      status = 'Warning';
      color = Colors.orange;
      icon = Icons.warning_amber_rounded;
    } else {
      status = 'Inactive';
      color = Colors.red;
      icon = Icons.remove_circle_outline;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
            Text(
              status,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty && _selectedRole == null
                ? 'No users yet'
                : 'No users found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty && _selectedRole == null
                ? 'Users will appear here'
                : 'Try adjusting your filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    final month = months[date.month - 1];
    final day = date.day;
    
    // Add year if different from current year
    if (date.year != now.year) {
      return '$month $day, ${date.year}';
    }
    
    return '$month $day';
  }
}
