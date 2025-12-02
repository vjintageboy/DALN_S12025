import 'package:cloud_firestore/cloud_firestore.dart';

/// Trạng thái phòng chat
enum ChatRoomStatus {
  active,
  archived,
}

class ChatRoom {
  final String id;
  final String appointmentId;
  final List<String> participants;
  final ChatRoomStatus status;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  ChatRoom({
    required this.id,
    required this.appointmentId,
    required this.participants,
    required this.status,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageTime,
  });

  /// Chuyển object thành map để lưu Firestore
  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'participants': participants,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
    };
  }

  /// Tạo object từ Firestore DocumentSnapshot
  factory ChatRoom.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw StateError(
        'ChatRoom.fromSnapshot: Document ${doc.id} không chứa dữ liệu.',
      );
    }

    return ChatRoom(
      id: doc.id,
      appointmentId: data['appointmentId']?.toString() ?? '',
      participants: _parseParticipants(data['participants']),
      status: _parseStatus(data['status']),
      createdAt: _parseTimestamp(data['createdAt']),
      lastMessage: data['lastMessage']?.toString(),
      lastMessageTime: _parseNullableTimestamp(data['lastMessageTime']),
    );
  }

  // ---------------------------------------------------------------------------
  // 🔒 SAFE PARSERS – Tránh crash nếu dữ liệu bị thiếu hoặc sai format
  // ---------------------------------------------------------------------------

  static List<String> _parseParticipants(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static ChatRoomStatus _parseStatus(dynamic value) {
    if (value is String) {
      return ChatRoomStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ChatRoomStatus.active,
      );
    }
    return ChatRoomStatus.active;
  }

  static DateTime _parseTimestamp(dynamic ts) {
    if (ts is Timestamp) return ts.toDate();
    if (ts is DateTime) return ts;
    return DateTime.now();
  }

  static DateTime? _parseNullableTimestamp(dynamic ts) {
    if (ts == null) return null;
    return _parseTimestamp(ts);
  }
}
