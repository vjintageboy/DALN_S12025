import 'package:flutter/foundation.dart';
import 'package:n04_app/dummy_firebase.dart';

import '../models/chat_room.dart';
import '../models/chat_message.dart';
import '../models/appointment.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create or get existing chat room
  Future<String> createOrGetChatRoom({
    required String appointmentId,
    required String userId,
    required String expertId,
  }) async {
    try {
      // 1. Check if a chat room already exists between these two participants
      // Firestore limitation: array-contains can only check one value.
      // We check for userId, then filter for expertId.
      final querySnapshot = await _db
          .collection('chat_rooms')
          .where('participants', arrayContains: userId)
          .get();

      DocumentSnapshot? existingRoom;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        if (participants.contains(expertId)) {
          existingRoom = doc;
          break;
        }
      }

      if (existingRoom != null) {
        // Update the existing room with the new appointmentId
        await existingRoom.reference.update({
          'appointmentId': appointmentId,
          'lastMessage':
              'System: Cuộc trò chuyện đã được tạo sau khi đặt lịch.',
          'lastMessageTime': FieldValue.serverDateTime(),
        });

        // Send system message
        await sendMessage(
          roomId: existingRoom.id,
          senderId: 'system',
          content: 'Bạn đã được kết nối với Expert cho buổi tư vấn mới.',
          type: MessageType.system,
        );

        return existingRoom.id;
      }

      // 2. Create new room if not exists
      final docRef = _db.collection('chat_rooms').doc();
      final chatRoom = ChatRoom(
        id: docRef.id,
        appointmentId: appointmentId,
        participants: [userId, expertId],
        status: ChatRoomStatus.active,
        createdAt: DateTime.now(),
        lastMessage: 'System: Cuộc trò chuyện đã được tạo sau khi đặt lịch.',
        lastMessageTime: DateTime.now(),
      );

      await docRef.set(chatRoom.toMap());

      // Add initial system message
      await sendMessage(
        roomId: docRef.id,
        senderId: 'system',
        content:
            'Bạn đã được kết nối với Expert cho buổi tư vấn. Hãy bắt đầu trò chuyện nếu bạn muốn trao đổi trước buổi hẹn.',
        type: MessageType.system,
      );

      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating/getting chat room: $e');
      rethrow;
    }
  }

  // Wrapper for backward compatibility
  Future<String> createChatRoom({
    required String appointmentId,
    required String userId,
    required String expertId,
  }) async {
    return createOrGetChatRoom(
      appointmentId: appointmentId,
      userId: userId,
      expertId: expertId,
    );
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
        'lastMessageTime': (message.timestamp),
      });
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
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
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromSnapshot(doc))
              .toList(),
        );
  }

  // Get user's chat rooms
  Stream<List<ChatRoom>> getUserChats(String userId) {
    return _db
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ChatRoom.fromSnapshot(doc)).toList(),
        );
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
      debugPrint('❌ Error getting chat room: $e');
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
