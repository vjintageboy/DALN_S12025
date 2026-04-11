import 'package:flutter_test/flutter_test.dart';
import 'package:n04_app/ai/disclaimer.dart';

void main() {
  group('DisclaimerInjector.maybeAdd — trigger detection', () {
    test('injects disclaimer when userInput contains "trầm cảm"', () {
      // Verify pattern matches directly
      final directPattern = RegExp(r'trầm\s*cảm', caseSensitive: false);
      expect(directPattern.hasMatch('Em nghĩ em bị trầm cảm'), isTrue,
          reason: 'pattern should match input directly');

      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'Bạn nên thử meditation nhé.',
        userInput: 'Em nghĩ em bị trầm cảm',
      );
      expect(result.contains('⚕️'), isTrue,
          reason: 'result should contain disclaimer emoji');
      expect(result.contains('KHÔNG thay thế'), isTrue);
    });

    test('injects disclaimer when aiResponse contains "depression"', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse:
            'Depression can be challenging. Meditation may help you feel better.',
        userInput: 'Hello',
      );
      expect(result.contains('⚕️'), isTrue);
    });

    test('injects disclaimer when userInput contains "lo âu"', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'Hãy thử hít thở sâu nhé.',
        userInput: 'Em hay lo âu lắm',
      );
      expect(result.contains('⚕️'), isTrue);
    });

    test('injects disclaimer when userInput contains "mất ngủ"', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'Bạn thử meditation cho giấc ngủ chưa?',
        userInput: 'Em bị mất ngủ thường xuyên',
      );
      expect(result.contains('⚕️'), isTrue);
    });

    test('injects disclaimer for "căng thẳng"', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'Căng thẳng có thể giảm bằng thiền.',
        userInput: 'Em căng thẳng quá',
      );
      expect(result.contains('⚕️'), isTrue);
    });

    test('injects disclaimer for "anxiety" in English', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'Have you tried breathing exercises?',
        userInput: 'I have anxiety attacks',
      );
      expect(result.contains('⚕️'), isTrue);
    });

    test('injects disclaimer for "stress"', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'Try our relaxation meditation.',
        userInput: 'I have a lot of stress',
      );
      expect(result.contains('⚕️'), isTrue);
    });

    test('injects disclaimer for "triệu chứng" (symptoms)', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'Bạn nên nói chuyện với bác sĩ.',
        userInput: 'Em có triệu chứng mất ngủ',
      );
      expect(result.contains('⚕️'), isTrue);
    });

    test('injects disclaimer for "chẩn đoán" (diagnosis)', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'Tôi không thể chẩn đoán.',
        userInput: 'Bạn có thể chẩn đoán cho em không?',
      );
      expect(result.contains('⚕️'), isTrue);
    });

    test('injects disclaimer for "thuốc" (medication)', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'Bạn nên hỏi bác sĩ về thuốc.',
        userInput: 'Em muốn uống thuốc cho hết buồn',
      );
      expect(result.contains('⚕️'), isTrue);
    });

    test('injects disclaimer for "rối loạn" (disorder)', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'Rối loạn lo âu cần được điều trị.',
        userInput: 'Em nghĩ em bị rối loạn',
      );
      expect(result.contains('⚕️'), isTrue);
    });

    test('injects disclaimer for "tâm thần"', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'Bạn nên gặp bác sĩ tâm thần.',
        userInput: 'Em cần gặp bác sĩ tâm thần',
      );
      expect(result.contains('⚕️'), isTrue);
    });
  });

  group('DisclaimerInjector.maybeAdd — no injection (safe inputs)', () {
    test('no disclaimer for normal greeting', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'Xin chào! Em cần giúp gì?',
        userInput: 'Chào bạn',
      );
      expect(result.contains('⚕️'), isFalse);
      expect(result, 'Xin chào! Em cần giúp gì?');
    });

    test('no disclaimer for meditation request', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'Em thử meditation 10 phút nhé!',
        userInput: 'Cho em meditation với',
      );
      expect(result.contains('⚕️'), isFalse);
    });

    test('no disclaimer for mood tracking', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'Hôm nay em thấy mood thế nào?',
        userInput: 'Em muốn ghi nhận tâm trạng',
      );
      expect(result.contains('⚕️'), isFalse);
    });

    test('no disclaimer for expert booking', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'Em vào tab Chuyên gia để đặt lịch nhé!',
        userInput: 'Làm sao đặt lịch?',
      );
      expect(result.contains('⚕️'), isFalse);
    });
  });

  group('DisclaimerInjector.maybeAdd — idempotency', () {
    test('does not duplicate disclaimer if already present (⚕️)', () {
      const withDisclaimer =
          'Some response ⚕️ _Lưu ý: KHÔNG thay thế chẩn đoán._';
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: withDisclaimer,
        userInput: 'Em bị trầm cảm',
      );
      // Count occurrences of ⚕️ — should be exactly 1
      final count = '⚕️'.allMatches(result).length;
      expect(count, 1, reason: 'disclaimer should not be duplicated');
    });

    test('does not duplicate if "không thay thế" already present', () {
      const withDisclaimer = 'Response\n\n⚕️ không thay thế chẩn đoán y khoa.';
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: withDisclaimer,
        userInput: 'Em bị trầm cảm',
      );
      final count = 'không thay thế'.allMatches(result.toLowerCase()).length;
      expect(count, 1, reason: 'disclaimer should not be duplicated');
    });

    test('does not duplicate if "not a substitute" already present', () {
      const withDisclaimer = 'Response\n\n⚕️ This is not a substitute for medical advice.';
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: withDisclaimer,
        userInput: 'I have depression',
      );
      final count = 'not a substitute'.allMatches(result.toLowerCase()).length;
      expect(count, 1, reason: 'disclaimer should not be duplicated');
    });
  });

  group('DisclaimerInjector.maybeAdd — edge cases', () {
    test('returns empty string unchanged', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: '',
        userInput: 'Em bị trầm cảm',
      );
      expect(result, '');
    });

    test('returns whitespace-only unchanged', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: '   ',
        userInput: 'Em bị trầm cảm',
      );
      expect(result, '   ');
    });

    test('handles null userInput', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'Normal response',
        userInput: null,
      );
      expect(result, 'Normal response');
    });

    test('handles special characters in response', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'Response with !@#\$%^&*()',
        userInput: 'Em bị trầm cảm',
      );
      expect(result.contains('⚕️'), isTrue);
      expect(result.contains('!@#\$%^&*()'), isTrue);
    });

    test('handles very long response', () {
      final longResponse = 'A' * 10000;
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: longResponse,
        userInput: 'Em bị trầm cảm',
      );
      expect(result.startsWith(longResponse), isTrue);
      expect(result.endsWith('_'), isTrue);
      expect(result.length, greaterThan(longResponse.length));
    });

    test('disclaimer appended at end of response', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'This is the answer.',
        userInput: 'Em bị trầm cảm',
      );
      expect(result.endsWith('y tế._'), isTrue,
          reason: 'disclaimer should be at the very end');
    });

    test('disclaimer includes newline separator', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'Answer',
        userInput: 'Em bị trầm cảm',
      );
      expect(result.contains('\n\n⚕️'), isTrue,
          reason: 'disclaimer should be separated by double newline');
    });

    test('handles Vietnamese no-diacritic input "tram cam"', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'Bạn nên thử thiền nhé.',
        userInput: 'Em bi tram cam',
      );
      expect(result.contains('⚕️'), isTrue);
    });

    test('handles "hoang so" (no diacritics for "hoảng sợ")', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'Hãy bình tĩnh.',
        userInput: 'Em hay hoang so lam',
      );
      expect(result.contains('⚕️'), isTrue);
    });

    test('handles "mat ngu" (no diacritics for "mất ngủ")', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'Ngủ sớm nhé.',
        userInput: 'Em bi mat ngu',
      );
      expect(result.contains('⚕️'), isTrue);
    });
  });

  group('DisclaimerInjector — disclaimer text content', () {
    test('disclaimer mentions AI assistant role', () {
      // Trigger via response content
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'Tôi là AI và bạn bị trầm cảm.',
        userInput: 'Hello',
      );
      expect(result.contains('AI'), isTrue);
    });

    test('disclaimer mentions not replacing medical diagnosis', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'Bạn có triệu chứng depression.',
        userInput: 'Hello',
      );
      expect(result.contains('KHÔNG thay thế chẩn đoán'), isTrue);
    });

    test('disclaimer suggests contacting professional', () {
      final result = DisclaimerInjector.maybeAdd(
        aiResponse: 'Bạn nên gặp chuyên gia lo âu.',
        userInput: 'Hello',
      );
      expect(result.contains('chuyên gia'), isTrue);
    });
  });
}
