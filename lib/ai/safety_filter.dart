/// Safety Filter — Pre-processing middleware for user input.
///
/// Combines regex-based keyword detection with severity levels to identify
/// self-harm, suicide, and dangerous content BEFORE sending to Gemini API.
///
/// When a high-severity trigger is detected, the caller should BYPASS the AI
/// and return an emergency payload instead.
library;

import '../core/config/system_prompt.dart';

/// Result of a safety check.
class SafetyResult {
  final bool isSafe;
  final SafetyLevel level;
  final String? triggeredKeyword;
  final String? emergencyMessage;

  const SafetyResult.safe()
      : isSafe = true,
        level = SafetyLevel.safe,
        triggeredKeyword = null,
        emergencyMessage = null;

  const SafetyResult.unsafe({
    required this.level,
    this.triggeredKeyword,
    this.emergencyMessage,
  }) : isSafe = false;

  /// Whether caller should bypass AI and return emergency payload.
  bool get shouldBypassAI => level == SafetyLevel.critical;
}

enum SafetyLevel {
  safe,
  warning,   // non-critical — allow AI but flag for disclaimer
  critical,  // self-harm / suicide — bypass AI entirely
}

// ─── Keyword dictionaries ─────────────────────────────────────────

/// Critical keywords — immediate emergency bypass.
/// Covers self-harm, suicide in both English and Vietnamese.
final List<RegExp> _criticalPatterns = [
  // Self-harm / suicide (Vietnamese)
  RegExp(r'tự\s*tử', caseSensitive: false),
  RegExp(r'tu\s*tu', caseSensitive: false),          // no-dialect variant
  RegExp(r'tự\s*sát', caseSensitive: false),
  RegExp(r'tu\s*sat', caseSensitive: false),
  RegExp(r'muốn\s*chết', caseSensitive: false),
  RegExp(r'muon\s*chet', caseSensitive: false),       // no-diacritic
  RegExp(r'không\s*muốn\s*sống', caseSensitive: false),
  RegExp(r'khong\s*muon\s*song', caseSensitive: false),
  RegExp(r'giết\s*chết', caseSensitive: false),
  RegExp(r'giết\s*mình', caseSensitive: false),
  RegExp(r'tự\s*làm\s*hại', caseSensitive: false),
  RegExp(r'tự\s*tổn\s*thương', caseSensitive: false),
  RegExp(r'cắt\s*(mình|tay)', caseSensitive: false),
  RegExp(r'đâm\s*(mình|chết)', caseSensitive: false),

  // Self-harm / suicide (English)
  RegExp(r'\bsuicide\b', caseSensitive: false),
  RegExp(r'\bkill\s*myself\b', caseSensitive: false),
  RegExp(r'\bkill\s*me\b', caseSensitive: false),
  RegExp(r'\bhurt\s*myself\b', caseSensitive: false),
  RegExp(r'\bself[ -]?harm\b', caseSensitive: false),
  RegExp(r'\bend\s*my\s*life\b', caseSensitive: false),
  RegExp(r'\bdie\b', caseSensitive: false),
];

/// Warning keywords — not critical but warrant a medical disclaimer.
final List<RegExp> _warningPatterns = [
  // Mental health symptoms (Vietnamese)
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
  RegExp(r'panic', caseSensitive: false),
  RegExp(r'depression', caseSensitive: false),
  RegExp(r'anxiety', caseSensitive: false),
  RegExp(r'stress', caseSensitive: false),
  RegExp(r'chán\s*nản', caseSensitive: false),
  RegExp(r'chan\s*nan', caseSensitive: false),
];

// ─── Public API ───────────────────────────────────────────────────

/// Check user input for safety concerns.
///
/// Returns [SafetyResult] indicating whether the input is safe,
/// needs a warning disclaimer, or requires emergency bypass.
class SafetyFilter {
  /// Run safety check on user input.
  static SafetyResult check(String input) {
    if (input.trim().isEmpty) {
      return const SafetyResult.safe();
    }

    // Normalize: collapse whitespace, lowercase, strip accents for matching
    final normalized = _normalize(input);

    // Check critical patterns
    for (final pattern in _criticalPatterns) {
      if (pattern.hasMatch(normalized) || pattern.hasMatch(input)) {
        return SafetyResult.unsafe(
          level: SafetyLevel.critical,
          triggeredKeyword: pattern.pattern,
          emergencyMessage: SystemPromptTemplate.buildEmergency(),
        );
      }
    }

    // Check warning patterns
    for (final pattern in _warningPatterns) {
      if (pattern.hasMatch(normalized) || pattern.hasMatch(input)) {
        return SafetyResult.unsafe(
          level: SafetyLevel.warning,
          triggeredKeyword: pattern.pattern,
        );
      }
    }

    return const SafetyResult.safe();
  }

  /// Normalize text for more robust keyword matching.
  ///
  /// - Lowercases
  /// - Collapses multiple spaces
  /// - Strips Vietnamese diacritics (Telex-style removal) to catch
  ///   no-diacritic user input like "muon chet" → matches "muốn chết".
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
      'À', 'Á', 'Ạ', 'Ả', 'Ã', 'Â', 'Ầ', 'Ấ', 'Ậ', 'Ẩ', 'Ẫ', 'Ă',
      'Ằ', 'Ắ', 'Ặ', 'Ẳ', 'Ẵ', 'È', 'É', 'Ẹ', 'Ẻ', 'Ẽ', 'Ê', 'Ề',
      'Ế', 'Ệ', 'Ể', 'Ễ', 'Ì', 'Í', 'Ị', 'Ỉ', 'Ĩ', 'Ò', 'Ó', 'Ọ',
      'Ỏ', 'Õ', 'Ô', 'Ồ', 'Ố', 'Ộ', 'Ổ', 'Ỗ', 'Ơ', 'Ờ', 'Ớ', 'Ợ',
      'Ở', 'Ỡ', 'Ù', 'Ú', 'Ụ', 'Ủ', 'Ũ', 'Ư', 'Ừ', 'Ứ', 'Ự', 'Ử',
      'Ữ', 'Ỳ', 'Ý', 'Ỵ', 'Ỷ', 'Ỹ', 'Đ',
    ];
    const ascii = [
      'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a',
      'a', 'a', 'a', 'a', 'a', 'e', 'e', 'e', 'e', 'e', 'e', 'e',
      'e', 'e', 'e', 'e', 'i', 'i', 'i', 'i', 'i', 'o', 'o', 'o',
      'o', 'o', 'o', 'o', 'o', 'o', 'o', 'o', 'o', 'o', 'o', 'o',
      'o', 'o', 'o', 'u', 'u', 'u', 'u', 'u', 'u', 'u', 'u', 'u',
      'u', 'u', 'u', 'u', 'u', 'u', 'u', 'd',
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
}
