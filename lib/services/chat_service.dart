import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../models/chat_room.dart';
import '../models/chat_message.dart';
import '../models/appointment.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create a new chat room linked to an appointment
  Future<String> createChatRoom({
    required String appointmentId,
    required String userId,
    required String expertId,
  }) async {
    try {
      // Check if room already exists for this appointment
      final existingQuery = await _db
          .collection('chat_rooms')
          .where('appointmentId', isEqualTo: appointmentId)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        return existingQuery.docs.first.id;
      }

      final docRef = _db.collection('chat_rooms').doc();
      final chatRoom = ChatRoom(
        id: docRef.id,
        appointmentId: appointmentId,
        participants: [userId, expertId],
        status: ChatRoomStatus.active,
        createdAt: DateTime.now(),
        lastMessage: 'Chat room created',
        lastMessageTime: DateTime.now(),
      );

      await docRef.set(chatRoom.toMap());

      // Add initial system message
      await sendMessage(
        roomId: docRef.id,
        senderId: 'system',
        content: 'Phòng chat đã được tạo. Bạn có thể gửi câu hỏi ngắn cho chuyên gia.',
        type: MessageType.system,
      );

      return docRef.id;
    } catch (e) {
      print('❌ Error creating chat room: $e');
      rethrow;
    }
  }

  // Send a message
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    try {
      final docRef = _db
          .collection('chat_rooms')
          .doc(roomId)
          .collection('messages')
          .doc();

      final message = ChatMessage(
        id: docRef.id,
        senderId: senderId,
        content: content,
        type: type,
        timestamp: DateTime.now(),
      );

      await docRef.set(message.toMap());

      // Update last message in chat room
      await _db.collection('chat_rooms').doc(roomId).update({
        'lastMessage': type == MessageType.text ? content : '[${type.name}]',
        'lastMessageTime': Timestamp.fromDate(message.timestamp),
      });
    } catch (e) {
      print('❌ Error sending message: $e');
      rethrow;
    }
  }

  // Get chat stream
  Stream<List<ChatMessage>> getChatStream(String roomId) {
    return _db
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatMessage.fromSnapshot(doc)).toList());
  }

  // Get user's chat rooms
  Stream<List<ChatRoom>> getUserChats(String userId) {
    return _db
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatRoom.fromSnapshot(doc)).toList());
  }

  // Get chat room by ID
  Future<ChatRoom?> getChatRoom(String roomId) async {
    try {
      final doc = await _db.collection('chat_rooms').doc(roomId).get();
      if (doc.exists) {
        return ChatRoom.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      print('❌ Error getting chat room: $e');
      return null;
    }
  }

  // Check if user can send message based on appointment status and time
  bool canSendMessage(Appointment appointment, bool isExpert) {
    // If cancelled → No chat
    if (appointment.status == AppointmentStatus.cancelled) {
      return false;
    }

    // After consultation → unlimited chat
    if (appointment.status == AppointmentStatus.completed) {
      return true;
    }

    // Confirmed (before/during appointment)
    if (appointment.status == AppointmentStatus.confirmed) {
      final now = DateTime.now();
      final start = appointment.appointmentDate;
      final end = start.add(Duration(minutes: appointment.durationMinutes));

      // During appointment
      if (now.isAfter(start) && now.isBefore(end)) {
        return true;
      }

      // Pre-appointment → allowed (UI sẽ hạn chế user nếu cần)
      if (now.isBefore(start)) {
        return true;
      }

      // After appointment but not updated
      if (now.isAfter(end)) {
        return true;
      }
    }

    return false;
  }
  
  // Check video call permission
  bool canJoinVideoCall(Appointment appointment) {
    if (appointment.status != AppointmentStatus.confirmed) return false;
    
    final now = DateTime.now();
    final start = appointment.appointmentDate;
    final end = start.add(Duration(minutes: appointment.durationMinutes));
    
    // Join allowed 10 minutes before start
    final allowedStart = start.subtract(const Duration(minutes: 10));
    
    return now.isAfter(allowedStart) && now.isBefore(end);
  }
}
