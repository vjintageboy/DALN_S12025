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

  /// Send message
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
      // Get AI response
      final aiResponse = await _chatbotService.getAIResponse(text);
      _messages.insert(0, aiResponse);
    } catch (e) {
      final errorMessage = ChatMessage(
        message: 'Đã có lỗi xảy ra. Vui lòng thử lại.',
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
    _addWelcomeMessage();
    notifyListeners();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
