import 'package:flutter/material.dart';
import 'ai_chatbot_widget.dart';

/// Chatbot Wrapper - Wraps any page with chatbot functionality
/// Ensures proper context hierarchy for TextField/Overlay requirements
class ChatbotWrapper extends StatelessWidget {
  final Widget child;

  const ChatbotWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        child,
        // Global AI Chatbot overlay
        const AIChatbotWidget(),
      ],
    );
  }
}
