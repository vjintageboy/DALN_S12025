import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/chat_room.dart';
import '../../models/chat_message.dart';
import '../../models/appointment.dart';
import '../../services/chat_service.dart';
import '../../services/appointment_service.dart'; // To get appointment details

class ChatDetailPage extends StatefulWidget {
  final String roomId;
  final String expertName;
  final String expertId;

  const ChatDetailPage({
    super.key,
    required this.roomId,
    required this.expertName,
    required this.expertId,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final AppointmentService _appointmentService = AppointmentService(); // Need to fetch appointment
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  Appointment? _appointment;
  bool _isLoadingAppointment = true;

  @override
  void initState() {
    super.initState();
    _loadAppointment();
  }

  Future<void> _loadAppointment() async {
    try {
      // 1. Get ChatRoom to find appointmentId
      final chatRoom = await _chatService.getChatRoom(widget.roomId);
      if (chatRoom != null) {
        // 2. Get Appointment
        final appointment = await _appointmentService.getAppointmentById(chatRoom.appointmentId);
        if (mounted) {
          setState(() {
            _appointment = appointment;
            _isLoadingAppointment = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingAppointment = false);
      }
    } catch (e) {
      print('Error loading appointment: $e');
      if (mounted) setState(() => _isLoadingAppointment = false);
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    // Permission Check
    if (_appointment != null) {
      final canSend = _chatService.canSendMessage(_appointment!, false); // false = user role (assuming)
      if (!canSend) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn chưa thể gửi tin nhắn vào lúc này.')),
        );
        return;
      }
    }

    _chatService.sendMessage(
      roomId: widget.roomId,
      senderId: _currentUserId,
      content: _messageController.text.trim(),
    );

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Determine permissions
    bool canSend = false;
    bool canVideo = false;
    String? restrictionMessage;

    if (_appointment != null) {
      canSend = _chatService.canSendMessage(_appointment!, false);
      canVideo = _chatService.canJoinVideoCall(_appointment!);
      
      if (!canSend) {
        restrictionMessage = 'Chat bị khóa. Vui lòng đợi đến giờ hẹn.';
      } else if (_appointment!.status == AppointmentStatus.confirmed && 
                 DateTime.now().isBefore(_appointment!.appointmentDate)) {
        restrictionMessage = 'Bạn chỉ có thể gửi câu hỏi ngắn trước buổi hẹn.';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expertName),
        actions: [
          IconButton(
            icon: Icon(Icons.videocam, color: canVideo ? Colors.blue : Colors.grey),
            onPressed: canVideo
                ? () {
                    // Video call logic
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Video call feature coming soon')),
                    );
                  }
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cuộc gọi video chỉ mở 10 phút trước giờ hẹn.')),
                    );
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          if (restrictionMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.orange.shade100,
              child: Text(
                restrictionMessage,
                style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getChatStream(widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;
                    final isSystem = message.type == MessageType.system;

                    if (isSystem) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            message.content,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ),
                      );
                    }

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.content,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('HH:mm').format(message.timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: canSend,
                    decoration: InputDecoration(
                      hintText: canSend ? 'Type a message...' : 'Chat is currently restricted',
                      border: const OutlineInputBorder(),
                      filled: !canSend,
                      fillColor: !canSend ? Colors.grey.shade100 : null,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: canSend ? Colors.blue : Colors.grey),
                  onPressed: canSend ? _sendMessage : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
