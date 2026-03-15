import 'package:flutter/foundation.dart';
import 'package:n04_app/dummy_firebase.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/config/gemini_config.dart';

/// AI Chatbot Service - Xử lý logic chatbot và AI responses
class AIChatbotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Gemini AI Model
  GenerativeModel? _model;
  ChatSession? _chatSession;

  // Initialize Gemini model
  void _initializeGemini() {
    if (!GeminiConfig.isConfigured) return;

    _model = GenerativeModel(
      model: GeminiConfig.modelName,
      apiKey: GeminiConfig.apiKey,
      generationConfig: GenerationConfig(
        temperature: GeminiConfig.temperature,
        maxOutputTokens: GeminiConfig.maxOutputTokens,
      ),
      systemInstruction: Content.text(GeminiConfig.systemPrompt),
    );

    // Create chat session for context
    _chatSession = _model?.startChat();
  }

  /// Get AI response based on user message
  Future<ChatMessage> getAIResponse(String userMessage) async {
    try {
      // Initialize Gemini if not already done
      if (_model == null && GeminiConfig.isConfigured) {
        _initializeGemini();
      }

      // Get user context for personalization
      final user = _auth.currentUser;
      final isAdmin = await _checkIfAdmin(user?.uid);
      final userName = user?.displayName ?? 'bạn';

      // Build context message
      final contextMessage = _buildContextMessage(
        userMessage,
        userName,
        isAdmin,
      );

      // Try Gemini AI first
      if (_chatSession != null) {
        try {
          final response = await _chatSession!.sendMessage(
            Content.text(contextMessage),
          );

          final aiText = response.text?.trim();
          if (aiText != null && aiText.isNotEmpty) {
            return ChatMessage(
              message: aiText,
              isUser: false,
              timestamp: DateTime.now(),
            );
          }
        } catch (geminiError) {
          debugPrint('Gemini API error: $geminiError');
          // Fall back to rule-based response
        }
      }

      // Fallback: Rule-based response
      final response = _generateResponse(userMessage, isAdmin);
      return ChatMessage(
        message: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error getting AI response: $e');
      return ChatMessage(
        message: 'Xin lỗi, tôi gặp sự cố. Vui lòng thử lại sau. 🙏',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Get AI response with streaming (real-time typing effect)
  Stream<String> getAIResponseStream(String userMessage) async* {
    try {
      // Initialize Gemini if not already done
      if (_model == null && GeminiConfig.isConfigured) {
        _initializeGemini();
      }

      // Get user context
      final user = _auth.currentUser;
      final isAdmin = await _checkIfAdmin(user?.uid);
      final userName = user?.displayName ?? 'bạn';
      final contextMessage = _buildContextMessage(
        userMessage,
        userName,
        isAdmin,
      );

      // Try Gemini streaming
      if (_chatSession != null) {
        try {
          final responseStream = _chatSession!.sendMessageStream(
            Content.text(contextMessage),
          );

          await for (final chunk in responseStream) {
            final text = chunk.text;
            if (text != null) {
              yield text;
            }
          }
          return;
        } catch (geminiError) {
          debugPrint('Gemini streaming error: $geminiError');
          // Fall back to rule-based
        }
      }

      // Fallback: Rule-based with simulated streaming
      final response = _generateResponse(userMessage, isAdmin);
      yield response;
    } catch (e) {
      debugPrint('Error in streaming response: $e');
      yield 'Xin lỗi, tôi gặp sự cố. Vui lòng thử lại sau. 🙏';
    }
  }

  /// Reset chat session (clear context)
  void resetChatSession() {
    if (_model != null) {
      _chatSession = _model!.startChat();
    }
  }

  /// Build context message with user info
  String _buildContextMessage(
    String userMessage,
    String userName,
    bool isAdmin,
  ) {
    final role = isAdmin ? 'Admin' : 'Người dùng';
    return '''
[User: $userName | Role: $role]
$userMessage
''';
  }

  /// Check if user is admin
  Future<bool> _checkIfAdmin(String? uid) async {
    if (uid == null) return false;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  /// Generate AI response based on context
  String _generateResponse(String message, bool isAdmin) {
    final lowerMessage = message.toLowerCase();

    // Greetings
    if (_containsAny(lowerMessage, ['xin chào', 'chào', 'hello', 'hi'])) {
      return isAdmin
          ? '👋 Xin chào Admin! Tôi có thể giúp gì cho bạn hôm nay? Bạn có thể hỏi về quản lý người dùng, meditations, hoặc thống kê hệ thống.'
          : '👋 Xin chào! Tôi là trợ lý AI của Moodiki. Tôi có thể giúp bạn tìm meditations, theo dõi mood, hoặc đặt lịch với chuyên gia. Bạn cần giúp gì?';
    }

    // Help/Support
    if (_containsAny(lowerMessage, ['giúp', 'help', 'trợ giúp', 'hướng dẫn'])) {
      return isAdmin
          ? '📚 **Tôi có thể hỗ trợ bạn:**\n\n• Quản lý người dùng (ban/unban)\n• Quản lý meditations (thêm/sửa/xóa)\n• Xem thống kê hệ thống\n• Phân tích xu hướng người dùng\n\nBạn muốn làm gì?'
          : '📚 **Tôi có thể giúp bạn:**\n\n• Tìm meditations phù hợp\n• Theo dõi tâm trạng\n• Đặt lịch với chuyên gia\n• Quản lý streak\n• Tips về wellness\n\nHãy cho tôi biết bạn cần gì!';
    }

    // Meditation related
    if (_containsAny(lowerMessage, [
      'meditation',
      'thiền',
      'thư giãn',
      'relax',
    ])) {
      return '🧘‍♀️ Bạn đang tìm kiếm sự thư giãn? Chúng tôi có nhiều chương trình meditation:\n\n• **Meditation cho giấc ngủ** - Giúp bạn ngủ ngon hơn\n• **Giảm stress** - Thư giãn sau ngày làm việc\n• **Tập trung** - Nâng cao năng suất\n• **Chánh niệm** - Sống trong hiện tại\n\nBạn muốn khám phá loại nào?';
    }

    // Mood tracking
    if (_containsAny(lowerMessage, [
      'mood',
      'tâm trạng',
      'cảm xúc',
      'feeling',
    ])) {
      return '😊 Theo dõi tâm trạng giúp bạn hiểu rõ hơn về cảm xúc của mình!\n\nMỗi ngày, hãy dành vài giây để ghi lại cảm xúc. Bạn sẽ nhận được:\n\n• Insights về patterns cảm xúc\n• Gợi ý meditations phù hợp\n• Streak và achievements\n\nHôm nay bạn cảm thấy thế nào?';
    }

    // Expert/Appointment
    if (_containsAny(lowerMessage, [
      'expert',
      'chuyên gia',
      'tư vấn',
      'appointment',
      'đặt lịch',
    ])) {
      return '👨‍⚕️ Bạn muốn đặt lịch với chuyên gia?\n\nChúng tôi có đội ngũ chuyên gia tâm lý và wellness coaches sẵn sàng hỗ trợ bạn.\n\n**Cách đặt lịch:**\n1. Vào tab "Chuyên gia"\n2. Chọn chuyên gia phù hợp\n3. Chọn thời gian\n4. Xác nhận\n\nCuộc hẹn của bạn sẽ được xác nhận qua email!';
    }

    // Statistics (Admin)
    if (isAdmin &&
        _containsAny(lowerMessage, [
          'thống kê',
          'stats',
          'statistics',
          'số liệu',
        ])) {
      return '📊 Để xem thống kê chi tiết:\n\n• **Dashboard** - Tổng quan hệ thống\n• **User Analytics** - Phân tích người dùng\n• **Meditation Stats** - Thống kê meditations\n• **Engagement** - Tỷ lệ tương tác\n\nBạn muốn xem phần nào?';
    }

    // User management (Admin)
    if (isAdmin &&
        _containsAny(lowerMessage, [
          'user',
          'người dùng',
          'quản lý',
          'ban',
          'unban',
        ])) {
      return '👥 Quản lý người dùng:\n\n• Vào "Manage Users" để xem danh sách\n• Click vào user để xem chi tiết\n• Ban/Unban user nếu cần\n• Xem lịch sử hoạt động\n\nBạn cần làm gì cụ thể?';
    }

    // Streak/Progress
    if (_containsAny(lowerMessage, [
      'streak',
      'tiến độ',
      'progress',
      'thành tích',
    ])) {
      return '🔥 Streak của bạn:\n\nGhi nhận tâm trạng liên tục mỗi ngày để duy trì streak và nhận rewards!\n\n• **Daily check-in** - Ghi nhận mood\n• **Meditation** - Hoàn thành sessions\n• **Achievements** - Mở khóa thành tích\n\nTiếp tục cố gắng nhé! 💪';
    }

    // Tips/Advice
    if (_containsAny(lowerMessage, ['tip', 'lời khuyên', 'advice', 'gợi ý'])) {
      return '💡 **Tips hôm nay:**\n\n🌅 Bắt đầu ngày với 5 phút meditation\n💧 Uống đủ nước\n🚶‍♀️ Đi bộ 15 phút ngoài trời\n😴 Ngủ đủ 7-8 tiếng\n📱 Giảm screen time trước khi ngủ\n\nHãy chăm sóc bản thân mỗi ngày!';
    }

    // Default response with suggestions
    return '🤔 Tôi chưa hiểu rõ câu hỏi của bạn. Bạn có thể hỏi tôi về:\n\n• Meditations & relaxation\n• Mood tracking\n• Đặt lịch với chuyên gia\n• Tips về wellness\n${isAdmin ? '• Quản lý hệ thống (Admin)\n• Thống kê & analytics' : ''}\n\nHoặc nhập "Giúp" để xem hướng dẫn!';
  }

  /// Helper method to check if message contains any keyword
  bool _containsAny(String message, List<String> keywords) {
    return keywords.any((keyword) => message.contains(keyword));
  }

  /// Get quick reply suggestions based on context
  List<String> getQuickReplies({bool isAdmin = false}) {
    if (isAdmin) {
      return [
        'Xem thống kê',
        'Quản lý người dùng',
        'Danh sách meditations',
        'Giúp đỡ',
      ];
    }
    return [
      'Tìm meditation',
      'Ghi nhận tâm trạng',
      'Đặt lịch chuyên gia',
      'Tips hôm nay',
    ];
  }

  /// Save chat history to Firestore (optional)
  Future<void> saveChatHistory(List<ChatMessage> messages) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chat_history')
          .add({
            'messages': messages.map((m) => m.toMap()).toList(),
            'timestamp': FieldValue.serverDateTime(),
          });
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }
}

/// Chat Message Model
class ChatMessage {
  final String message;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.message,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      message: map['message'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
