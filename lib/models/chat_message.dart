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
      'sender_id': senderId,
      'content': content,
      'type': type.name,
      'is_pinned': isPinned,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id']?.toString() ?? '',
      senderId: map['sender_id']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isPinned: map['is_pinned'] == true,
    );
  }
}
