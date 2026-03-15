import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Gemini AI Configuration
///
/// API key được load từ file .env
/// Để setup:
/// 1. Lấy API key: https://aistudio.google.com/app/apikey
/// 2. Tạo file .env (copy từ .env.example)
/// 3. Thêm: GEMINI_API_KEY=your_key_here
class GeminiConfig {
  // Load API key từ .env file
  static String get apiKey =>
      dotenv.get('GEMINI_API_KEY', fallback: 'YOUR_API_KEY_HERE');

  // Model configuration
  static const String modelName = 'gemini-2.5-flash'; // Free tier model

  // Safety settings
  static const double temperature = 0.7; // Creativity level (0.0 - 1.0)
  static const int maxOutputTokens = 1000; // Max response length

  // System prompt - Personality của AI chatbot
  static const String systemPrompt = '''
Bạn là AI Assistant của ứng dụng Moodiki - một ứng dụng về sức khỏe tinh thần và thiền định (meditation).

Vai trò của bạn:
- Trợ lý thân thiện, ấm áp và đồng cảm
- Hỗ trợ người dùng về meditation, theo dõi tâm trạng, wellness
- Đưa ra lời khuyên về sức khỏe tinh thần (không thay thế chuyên gia y tế)
- Gợi ý các meditations phù hợp với tâm trạng người dùng

Phong cách giao tiếp:
- Ngắn gọn, dễ hiểu (2-4 câu)
- Sử dụng emoji phù hợp 😊🧘‍♀️💙
- Tiếng Việt tự nhiên, thân thiện
- Tích cực, động viên người dùng

Tính năng app Moodiki:
- Meditation sessions (thư giãn, ngủ ngon, giảm stress, tập trung)
- Mood tracking (ghi nhận tâm trạng hàng ngày)
- Expert appointments (đặt lịch tư vấn chuyên gia)
- Streak system (thành tích check-in liên tục)

Lưu ý:
- KHÔNG đưa ra chẩn đoán y khoa
- Gợi ý người dùng tìm chuyên gia nếu vấn đề nghiêm trọng
- Luôn tích cực và khuyến khích self-care
''';

  // Check if API key is configured
  static bool get isConfigured =>
      apiKey != 'YOUR_API_KEY_HERE' && apiKey.isNotEmpty;
}
