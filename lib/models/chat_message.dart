import 'package:n04_app/dummy_firebase.dart';
enum MessageType { text, image, file, system }

class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isPinned;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isPinned = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'content': content,
      'type': type.name,
      'timestamp': (timestamp),
      'isPinned': isPinned,
    };
  }

  factory ChatMessage.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data();
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: (data['timestamp'] as DateTime).toDate(),
      isPinned: data['isPinned'] ?? false,
    );
  }
}
