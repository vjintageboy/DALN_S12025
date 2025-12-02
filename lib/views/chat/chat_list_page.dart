import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../services/chat_service.dart';
import '../../services/appointment_service.dart';
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
  AppointmentService get _appointmentService => AppointmentService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tin nhắn',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: _chatService.getUserChats(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
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
                children: const [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có tin nhắn nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
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
      future: _appointmentService.getAppointmentById(chatRoom.appointmentId),
      builder: (context, snapshot) {
        // Default values while loading or if error
        String displayName = 'Đang tải...';
        String appointmentTime = '';
        String avatarUrl = '';

        if (snapshot.hasData && snapshot.data != null) {
          final appointment = snapshot.data!;
          displayName = appointment.expertName;
          avatarUrl = appointment.expertAvatarUrl ?? '';
          
          final dateStr = DateFormat('dd/MM/yyyy').format(appointment.appointmentDate);
          final timeStr = DateFormat('HH:mm').format(appointment.appointmentDate);
          appointmentTime = 'Lịch hẹn: $timeStr - $dateStr';
        } else if (snapshot.connectionState == ConnectionState.done && snapshot.data == null) {
           // Fallback if appointment not found (rare)
           final otherUserId = chatRoom.participants.firstWhere(
            (id) => id != _currentUserId,
            orElse: () => 'Unknown',
          );
           displayName = 'Expert (ID: ${otherUserId.substring(0, min(5, otherUserId.length))}...)';
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
                Text(
                  appointmentTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
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
            // Determine expertId for navigation
            String expertId = '';
             if (snapshot.hasData && snapshot.data != null) {
                expertId = snapshot.data!.expertId;
             } else {
                expertId = chatRoom.participants.firstWhere(
                  (id) => id != _currentUserId,
                  orElse: () => '',
                );
             }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailPage(
                  roomId: chatRoom.id,
                  expertName: displayName,
                  expertId: expertId,
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  int min(int a, int b) => a < b ? a : b;
}
