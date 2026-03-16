import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/chat_service.dart';
import '../../services/appointment_service.dart';
import '../../services/supabase_service.dart';
import '../../models/chat_room.dart';
import '../../models/appointment.dart';
import 'chat_detail_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatService _chatService = ChatService();
  final AppointmentService _appointmentService = AppointmentService();
  final SupabaseService _supabaseService = SupabaseService();
  String get _currentAuthId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: _chatService.getUserChats(_currentAuthId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('❌ Chat List Error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chatRooms = snapshot.data ?? [];

          if (chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có tin nhắn nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  // DEBUG INFO
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.grey[200],
                    child: Column(
                      children: [
                        Text(
                          'Current Auth ID: $_currentAuthId',
                          style: const TextStyle(fontSize: 11),
                        ),
                        const Text(
                          'Querying: participants array-contains Auth ID',
                          style: TextStyle(fontSize: 11),
                        ),
                        Text(
                          'Chats Found: ${chatRooms.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: chatRooms.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              return _buildChatListItem(chatRoom);
            },
          );
        },
      ),
    );
  }

  Widget _buildChatListItem(ChatRoom chatRoom) {
    return FutureBuilder<Appointment?>(
      future: chatRoom.appointmentId != null && chatRoom.appointmentId!.isNotEmpty
          ? _appointmentService.getAppointmentById(chatRoom.appointmentId!)
          : Future.value(null),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final appointment = snapshot.data!;
          // Use _currentAuthId for comparison
          // Note: appointment.expertId is Profile ID, but we are comparing Auth IDs?
          // Wait, if we use Auth ID for chat, then chatRoom.participants has Auth IDs.
          // But appointment.expertId is still Profile ID.
          // So we need to check if _currentAuthId is in participants AND is NOT the user.
          // OR, we can just check if _currentAuthId == appointment.userId.
          // If I am the user, then isExpert = false.
          // If I am the expert, then _currentAuthId != appointment.userId.

          final isExpert = _currentAuthId != appointment.userId;

          if (isExpert) {
            // If I am the expert, I want to see the User's info
            return FutureBuilder<Map<String, String>>(
              future: _fetchUserInfo(appointment.userId),
              builder: (context, userSnapshot) {
                String displayName = 'Người dùng';
                String avatarUrl = '';

                if (userSnapshot.hasData) {
                  displayName = userSnapshot.data!['name'] ?? 'Người dùng';
                  avatarUrl = userSnapshot.data!['avatar'] ?? '';
                }

                return _buildTile(
                  context,
                  chatRoom,
                  appointment,
                  displayName,
                  avatarUrl,
                  isExpert,
                );
              },
            );
          } else {
            // If I am the user, I want to see the Expert's info
            return _buildTile(
              context,
              chatRoom,
              appointment,
              appointment.expertName,
              appointment.expertAvatarUrl ?? '',
              isExpert,
            );
          }
        } else if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data == null) {
          // Fallback if appointment not found
          final otherUserId = chatRoom.participants.firstWhere(
            (id) => id != _currentAuthId,
            orElse: () => 'Unknown',
          );
          return ListTile(
            title: Text(
              'Người dùng (ID: ${otherUserId.substring(0, min(5, otherUserId.length))}...)',
            ),
            subtitle: Text(chatRoom.lastMessage ?? ''),
          );
        }

        // Loading state
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTile(
    BuildContext context,
    ChatRoom chatRoom,
    Appointment appointment,
    String displayName,
    String avatarUrl,
    bool isExpert,
  ) {
    String appointmentTime = '';
    String statusText = '';
    Color statusColor = Colors.grey;

    final dateStr = DateFormat(
      'dd/MM/yyyy',
    ).format(appointment.appointmentDate);
    final timeStr = DateFormat('HH:mm').format(appointment.appointmentDate);
    appointmentTime = 'Lịch hẹn: $timeStr - $dateStr';

    // Determine status text and color
    switch (appointment.status) {
      case AppointmentStatus.cancelled:
        statusText = ' • Đã hủy';
        statusColor = Colors.red;
        break;
      case AppointmentStatus.completed:
        statusText = ' • Đã hoàn thành';
        statusColor = Colors.green;
        break;
      case AppointmentStatus.confirmed:
        // Optional: ' • Sắp tới'
        break;
      default:
        break;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
        child: avatarUrl.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text(
        displayName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            chatRoom.lastMessage ?? 'Chưa có tin nhắn',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w400,
            ),
          ),
          if (appointmentTime.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  appointmentTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (statusText.isNotEmpty)
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
      trailing: chatRoom.lastMessageTime != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('HH:mm').format(chatRoom.lastMessageTime!),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            )
          : null,
      onTap: () {
        // If I am expert, target is User (appointment.userId)
        // If I am user, target is Expert (appointment.expertId)
        final targetId = isExpert ? appointment.userId : appointment.expertId;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailPage(
              roomId: chatRoom.id,
              expertName: displayName, // Reusing this field for "Target Name"
              expertId: targetId, // Reusing this field for "Target ID"
              targetAvatarUrl: avatarUrl, // Pass the avatar URL
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, String>> _fetchUserInfo(String userId) async {
    String displayName = 'Người dùng';
    String avatarUrl = '';

    try {
      final profile = await _supabaseService.getUserProfile(userId);
      if (profile != null) {
        final fullName = profile['full_name'] as String?;
        avatarUrl = (profile['avatar_url'] as String?) ?? '';
        if (fullName != null && fullName.isNotEmpty) {
          displayName = fullName;
        }
      }
    } catch (e) {
      debugPrint('Error fetching user info: $e');
    }

    return {'name': displayName, 'avatar': avatarUrl};
  }

  int min(int a, int b) => a < b ? a : b;
}
