/// Medical Disclaimer Injector
///
/// Appends a subtle medical disclaimer to AI responses when the user input
/// or the AI response contains symptom-related / mental-health keywords.
///
/// The disclaimer is only added once (idempotent) and is appended at the
/// end of the response.
library;


/// Keywords that signal a medical disclaimer should be appended.
/// These are broader than the safety filter warning list — they cover
/// any mention of symptoms, diagnoses, or psychological conditions.
final List<RegExp> _disclaimerTriggerPatterns = [
  // Vietnamese symptom / condition keywords
  RegExp(r'trầm\s*cảm', caseSensitive: false),
  RegExp(r'tram\s*cam', caseSensitive: false),
  RegExp(r'lo\s*âu', caseSensitive: false),
  RegExp(r'hoảng\s*sợ', caseSensitive: false),
  RegExp(r'mất\s*ngủ', caseSensitive: false),
  RegExp(r'mat\s*ngu', caseSensitive: false),
  RegExp(r'căng\s*thẳng', caseSensitive: false),
  RegExp(r'cang\s*thang', caseSensitive: false),
  RegExp(r'khóc', caseSensitive: false),
  RegExp(r'sợ\s*hãi', caseSensitive: false),
  RegExp(r'chán\s*nản', caseSensitive: false),
  RegExp(r'chan\s*nan', caseSensitive: false),
  RegExp(r'ám\s*ảnh', caseSensitive: false),
  RegExp(r'am\s*anh', caseSensitive: false),
  RegExp(r'hoảng\s*sợ', caseSensitive: false),
  RegExp(r'hoang\s*so', caseSensitive: false),
  RegExp(r'binge\s*eating', caseSensitive: false),
  RegExp(r'rối\s*loạn', caseSensitive: false),
  RegExp(r'roi\s*loan', caseSensitive: false),
  RegExp(r'tâm\s*thần', caseSensitive: false),
  RegExp(r'tam\s*than', caseSensitive: false),
  RegExp(r'bệnh', caseSensitive: false),
  RegExp(r'triệu\s*chứng', caseSensitive: false),
  RegExp(r'trieu\s*chung', caseSensitive: false),
  RegExp(r'chẩn\s*đoán', caseSensitive: false),
  RegExp(r'chan\s*doan', caseSensitive: false),
  RegExp(r'thuốc', caseSensitive: false),
  RegExp(r'thuoc', caseSensitive: false),
  RegExp(r'trị\s*liệu', caseSensitive: false),
  RegExp(r'tri\s*lieu', caseSensitive: false),

  // English equivalents
  RegExp(r'\bdepression\b', caseSensitive: false),
  RegExp(r'\banxiety\b', caseSensitive: false),
  RegExp(r'\bpanic\s*attack\b', caseSensitive: false),
  RegExp(r'\binsomnia\b', caseSensitive: false),
  RegExp(r'\bptsd\b', caseSensitive: false),
  RegExp(r'\bocd\b', caseSensitive: false),
  RegExp(r'\bbipolar\b', caseSensitive: false),
  RegExp(r'\bschizophrenia\b', caseSensitive: false),
  RegExp(r'\btherapy\b', caseSensitive: false),
  RegExp(r'\bmedication\b', caseSensitive: false),
  RegExp(r'\bdiagnos', caseSensitive: false),
  RegExp(r'\bsymptom', caseSensitive: false),
  RegExp(r'\bdisorder\b', caseSensitive: false),
  RegExp(r'\bstress\b', caseSensitive: false),
];

const String _disclaimerText =
    '\n\n⚕️ _Lưu ý: Tôi là AI trợ lý, KHÔNG thay thế chẩn đoán hoặc điều trị y khoa. '
    'Nếu bạn đang trải qua khủng hoảng, vui lòng liên hệ chuyên gia y tế._';

class DisclaimerInjector {
  /// Append a medical disclaimer if any trigger keywords are present
  /// in either the [userInput] or the [aiResponse].
  ///
  /// Returns the original response unchanged if no triggers match,
  /// or the response with the disclaimer appended.
  static String maybeAdd({
    required String aiResponse,
    String? userInput,
  }) {
    if (aiResponse.trim().isEmpty) return aiResponse;

    // Already contains a disclaimer — don't duplicate.
    if (_alreadyHasDisclaimer(aiResponse)) return aiResponse;

    final combined = [aiResponse, userInput ?? ''].join(' ');
    final normalized = _normalize(combined);

    for (final pattern in _disclaimerTriggerPatterns) {
      final matchCombined = pattern.hasMatch(combined);
      final matchNormalized = pattern.hasMatch(normalized);
      if (matchCombined || matchNormalized) {
        return '$aiResponse$_disclaimerText';
      }
    }

    return aiResponse;
  }

  /// Normalize text for keyword matching (lowercase + collapse whitespace).
  static String _normalize(String input) {
    var text = input.toLowerCase().trim();
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    text = _stripVietnameseDiacritics(text);
    return text;
  }

  /// Remove Vietnamese diacritics for fuzzy matching.
  static String _stripVietnameseDiacritics(String input) {
    const vietnamese = [
      'à', 'á', 'ạ', 'ả', 'ã', 'â', 'ầ', 'ấ', 'ậ', 'ẩ', 'ẫ', 'ă',
      'ằ', 'ắ', 'ặ', 'ẳ', 'ẵ', 'è', 'é', 'ẹ', 'ẻ', 'ẽ', 'ê', 'ề',
      'ế', 'ệ', 'ể', 'ễ', 'ì', 'í', 'ị', 'ỉ', 'ĩ', 'ò', 'ó', 'ọ',
      'ỏ', 'õ', 'ô', 'ồ', 'ố', 'ộ', 'ổ', 'ỗ', 'ơ', 'ờ', 'ớ', 'ợ',
      'ở', 'ỡ', 'ù', 'ú', 'ụ', 'ủ', 'ũ', 'ư', 'ừ', 'ứ', 'ự', 'ử',
      'ữ', 'ỳ', 'ý', 'ỵ', 'ỷ', 'ỹ', 'đ',
    ];
    const ascii = [
      'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a',
      'a', 'a', 'a', 'a', 'a', 'e', 'e', 'e', 'e', 'e', 'e', 'e',
      'e', 'e', 'e', 'e', 'i', 'i', 'i', 'i', 'i', 'o', 'o', 'o',
      'o', 'o', 'o', 'o', 'o', 'o', 'o', 'o', 'o', 'o', 'o', 'o',
      'o', 'o', 'o', 'u', 'u', 'u', 'u', 'u', 'u', 'u', 'u', 'u',
      'u', 'u', 'u', 'u', 'u', 'u', 'u', 'd',
    ];

    var result = input;
    for (var i = 0; i < vietnamese.length; i++) {
      result = result.replaceAll(vietnamese[i], ascii[i]);
    }
    return result;
  }

  /// Check whether the response already contains a disclaimer substring.
  static bool _alreadyHasDisclaimer(String response) {
    final lower = response.toLowerCase();
    return lower.contains('không thay thế chẩn đoán') ||
        lower.contains('not a substitute') ||
        lower.contains('không thay thế') ||
        lower.contains('⚕️');
  }
}
