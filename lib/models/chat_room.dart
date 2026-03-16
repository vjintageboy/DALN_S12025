/// Trạng thái phòng chat
enum ChatRoomStatus { active, archived }

class ChatRoom {
  final String id;
  final String? appointmentId;
  final List<String> participants;
  final ChatRoomStatus status;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  ChatRoom({
    required this.id,
    this.appointmentId,
    required this.participants,
    required this.status,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageTime,
  });

  /// Chuyển object thành map để lưu Supabase
  Map<String, dynamic> toMap() {
    return {
      'appointment_id': appointmentId,
      'status': status.name,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
    };
  }

  /// Tạo object từ Supabase row map
  factory ChatRoom.fromMap(Map<String, dynamic> map,
      {List<String>? participantIds}) {
    return ChatRoom(
      id: map['id']?.toString() ?? '',
      appointmentId: map['appointment_id'] as String?,
      participants: participantIds ?? [],
      status: _parseStatus(map['status']),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
              DateTime.now(),
      lastMessage: map['last_message']?.toString(),
      lastMessageTime:
          DateTime.tryParse(map['last_message_time']?.toString() ?? ''),
    );
  }

  // ---------------------------------------------------------------------------
  // 🔒 SAFE PARSERS
  // ---------------------------------------------------------------------------

  static ChatRoomStatus _parseStatus(dynamic value) {
    if (value is String) {
      return ChatRoomStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ChatRoomStatus.active,
      );
    }
    return ChatRoomStatus.active;
  }
}
