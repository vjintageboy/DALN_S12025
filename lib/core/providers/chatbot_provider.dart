import 'package:flutter/material.dart';
import '../../services/ai_chatbot_service.dart';

/// Chatbot Provider - Quản lý state của chatbot toàn app
class ChatbotProvider extends ChangeNotifier {
  final AIChatbotService _chatbotService = AIChatbotService();
  
  // State
  bool _isOpen = false;
  bool _isLoading = false;
  bool _isMinimized = false;
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();

  // Getters
  bool get isOpen => _isOpen;
  bool get isLoading => _isLoading;
  bool get isMinimized => _isMinimized;
  List<ChatMessage> get messages => _messages;
  TextEditingController get messageController => _messageController;

  /// Toggle chatbot panel
  void toggleChatbot() {
    _isOpen = !_isOpen;
    if (_isOpen && _messages.isEmpty) {
      // Add welcome message on first open
      _addWelcomeMessage();
    }
    notifyListeners();
  }

  /// Open chatbot
  void openChatbot() {
    _isOpen = true;
    if (_messages.isEmpty) {
      _addWelcomeMessage();
    }
    notifyListeners();
  }

  /// Close chatbot
  void closeChatbot() {
    _isOpen = false;
    _isMinimized = false;
    notifyListeners();
  }

  /// Toggle minimize/maximize
  void toggleMinimize() {
    _isMinimized = !_isMinimized;
    notifyListeners();
  }

  /// Add welcome message
  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      message: '👋 Xin chào! Tôi là AI Assistant của Moodiki. Tôi có thể giúp gì cho bạn?',
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.insert(0, welcomeMessage);
  }

  /// Send message with streaming support
  Future<void> sendMessage(String? message) async {
    final text = message ?? _messageController.text.trim();
    if (text.isEmpty) return;

    // Clear input
    _messageController.clear();

    // Add user message
    final userMessage = ChatMessage(
      message: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.insert(0, userMessage);
    notifyListeners();

    // Show loading
    _isLoading = true;
    notifyListeners();

    try {
      // Create placeholder for AI response
      final aiMessageIndex = 0;
      final aiMessage = ChatMessage(
        message: '',
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.insert(0, aiMessage);
      
      // Stream AI response (real-time typing effect)
      final responseStream = _chatbotService.getAIResponseStream(text);
      String fullResponse = '';
      
      await for (final chunk in responseStream) {
        fullResponse += chunk;
        
        // Update AI message with accumulated text
        _messages[aiMessageIndex] = ChatMessage(
          message: fullResponse,
          isUser: false,
          timestamp: aiMessage.timestamp,
        );
        notifyListeners();
      }
      
      // If no response received, use fallback
      if (fullResponse.isEmpty) {
        _messages[aiMessageIndex] = ChatMessage(
          message: 'Xin lỗi, tôi không thể trả lời lúc này. Vui lòng thử lại! 🙏',
          isUser: false,
          timestamp: DateTime.now(),
        );
      }
      
    } catch (e) {
      print('Error sending message: $e');
      final errorMessage = ChatMessage(
        message: 'Đã có lỗi xảy ra. Vui lòng thử lại. 😔',
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.insert(0, errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get quick replies
  Future<List<String>> getQuickReplies() async {
    // TODO: Check if user is admin
    return _chatbotService.getQuickReplies(isAdmin: false);
  }

  /// Clear chat history
  void clearChat() {
    _messages.clear();
    _chatbotService.resetChatSession(); // Reset Gemini context
    _addWelcomeMessage();
    notifyListeners();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
