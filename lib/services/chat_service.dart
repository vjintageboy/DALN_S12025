import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_room.dart';
import '../models/chat_message.dart';
import '../models/appointment.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create or get existing chat room
  Future<String> createOrGetChatRoom({
    required String appointmentId,
    required String userId,
    required String expertId,
  }) async {
    try {
      // 1. Check if a chat room already exists between these two participants
      final userRoomIds = await _getRoomIdsForUser(userId);
      final expertRoomIds = await _getRoomIdsForUser(expertId);

      // Find common room IDs
      final commonRoomIds =
          userRoomIds.where((id) => expertRoomIds.contains(id)).toList();

      if (commonRoomIds.isNotEmpty) {
        final existingRoomId = commonRoomIds.first;

        // Update the existing room with the new appointmentId
        await _supabase.from('chat_rooms').update({
          'appointment_id': appointmentId,
          'last_message':
              'System: Cuộc trò chuyện đã được tạo sau khi đặt lịch.',
          'last_message_time': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existingRoomId);

        // Send system message
        await sendMessage(
          roomId: existingRoomId,
          senderId: userId,
          content: 'Bạn đã được kết nối với Expert cho buổi tư vấn mới.',
          type: MessageType.system,
        );

        return existingRoomId;
      }

      // 2. Create new room if not exists
      final roomResponse = await _supabase
          .from('chat_rooms')
          .insert({
            'appointment_id': appointmentId,
            'status': ChatRoomStatus.active.name,
            'last_message':
                'System: Cuộc trò chuyện đã được tạo sau khi đặt lịch.',
            'last_message_time': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final newRoomId = roomResponse['id'].toString();

      // Add participants
      await _supabase.from('chat_participants').insert([
        {'room_id': newRoomId, 'user_id': userId},
        {'room_id': newRoomId, 'user_id': expertId},
      ]);

      // Add initial system message
      await sendMessage(
        roomId: newRoomId,
        senderId: userId,
        content:
            'Bạn đã được kết nối với Expert cho buổi tư vấn. Hãy bắt đầu trò chuyện nếu bạn muốn trao đổi trước buổi hẹn.',
        type: MessageType.system,
      );

      return newRoomId;
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
      await _supabase.from('messages').insert({
        'room_id': roomId,
        'sender_id': senderId,
        'content': content,
        'type': type.name,
      });

      // Update last message in chat room
      final displayContent =
          type == MessageType.text ? content : '[${type.name}]';
      await _supabase.from('chat_rooms').update({
        'last_message': displayContent,
        'last_message_time': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', roomId);
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      rethrow;
    }
  }

  // Get chat stream (real-time)
  Stream<List<ChatMessage>> getChatStream(String roomId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .map(
          (rows) => rows.map((row) => ChatMessage.fromMap(row)).toList(),
        );
  }

  // Get user's chat rooms
  Stream<List<ChatRoom>> getUserChats(String userId) async* {
    if (userId.isEmpty) {
      yield [];
      return;
    }

    // Get room IDs where user is a participant
    final roomIds = await _getRoomIdsForUser(userId);

    if (roomIds.isEmpty) {
      yield [];
      return;
    }

    // Stream chat rooms
    yield* _supabase
        .from('chat_rooms')
        .stream(primaryKey: ['id'])
        .order('last_message_time', ascending: false)
        .asyncMap((rows) async {
      // Filter to only rooms the user participates in
      final userRooms =
          rows.where((row) => roomIds.contains(row['id'].toString())).toList();

      if (userRooms.isEmpty) return <ChatRoom>[];

      // Batch fetch all participants for these rooms in one query
      final userRoomIds = userRooms.map((r) => r['id'].toString()).toList();
      final allParticipants = await _getParticipantsForRooms(userRoomIds);

      final chatRooms = <ChatRoom>[];
      for (final row in userRooms) {
        final roomId = row['id'].toString();
        final participants = allParticipants[roomId] ?? [];
        chatRooms.add(ChatRoom.fromMap(row, participantIds: participants));
      }
      return chatRooms;
    });
  }

  // Get chat room by ID
  Future<ChatRoom?> getChatRoom(String roomId) async {
    try {
      final data = await _supabase
          .from('chat_rooms')
          .select()
          .eq('id', roomId)
          .maybeSingle();

      if (data != null) {
        final participants = await _getParticipantsForRoom(roomId);
        return ChatRoom.fromMap(data, participantIds: participants);
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

  // -------------------------------------------------------------------------
  // PRIVATE HELPERS
  // -------------------------------------------------------------------------

  /// Get all room IDs that a user participates in
  Future<List<String>> _getRoomIdsForUser(String userId) async {
    try {
      final rows = await _supabase
          .from('chat_participants')
          .select('room_id')
          .eq('user_id', userId);

      return (rows as List)
          .map((row) => row['room_id'].toString())
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting room IDs for user: $e');
      return [];
    }
  }

  /// Get participant user IDs for a room
  Future<List<String>> _getParticipantsForRoom(String roomId) async {
    try {
      final rows = await _supabase
          .from('chat_participants')
          .select('user_id')
          .eq('room_id', roomId);

      return (rows as List)
          .map((row) => row['user_id'].toString())
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting participants for room: $e');
      return [];
    }
  }

  /// Batch fetch participants for multiple rooms in one query
  Future<Map<String, List<String>>> _getParticipantsForRooms(
      List<String> roomIds) async {
    try {
      final rows = await _supabase
          .from('chat_participants')
          .select('room_id, user_id')
          .inFilter('room_id', roomIds);

      final result = <String, List<String>>{};
      for (final row in (rows as List)) {
        final roomId = row['room_id'].toString();
        final userId = row['user_id'].toString();
        result.putIfAbsent(roomId, () => []).add(userId);
      }
      return result;
    } catch (e) {
      debugPrint('❌ Error batch getting participants: $e');
      return {};
    }
  }
}
