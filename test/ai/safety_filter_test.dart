import 'package:flutter_test/flutter_test.dart';
import 'package:n04_app/ai/safety_filter.dart';
import 'dart:async';

void main() {
  group('SafetyFilter.check — Critical (self-harm / suicide)', () {
    test('detects Vietnamese "tự tử"', () {
      final result = SafetyFilter.check('Tôi muốn tự tử');
      expect(result.isSafe, isFalse);
      expect(result.level, SafetyLevel.critical);
      expect(result.shouldBypassAI, isTrue);
      expect(result.emergencyMessage, isNotNull);
    });

    test('detects Vietnamese "tự sát"', () {
      final result = SafetyFilter.check('đang nghĩ đến tự sát');
      expect(result.isSafe, isFalse);
      expect(result.level, SafetyLevel.critical);
      expect(result.shouldBypassAI, isTrue);
    });

    test('detects "muốn chết" (no diacritics: "muon chet")', () {
      final result = SafetyFilter.check('Tôi muon chet');
      expect(result.isSafe, isFalse);
      expect(result.level, SafetyLevel.critical);
      expect(result.shouldBypassAI, isTrue);
    });

    test('detects "không muốn sống" (no diacritics)', () {
      final result = SafetyFilter.check('Em khong muon song nua');
      expect(result.isSafe, isFalse);
      expect(result.level, SafetyLevel.critical);
      expect(result.shouldBypassAI, isTrue);
    });

    test('detects English "suicide"', () {
      final result = SafetyFilter.check('I am thinking about suicide');
      expect(result.isSafe, isFalse);
      expect(result.level, SafetyLevel.critical);
      expect(result.shouldBypassAI, isTrue);
    });

    test('detects "kill myself"', () {
      final result = SafetyFilter.check('I want to kill myself');
      expect(result.isSafe, isFalse);
      expect(result.level, SafetyLevel.critical);
      expect(result.shouldBypassAI, isTrue);
    });

    test('detects "self-harm"', () {
      final result = SafetyFilter.check('I have urges to self-harm');
      expect(result.isSafe, isFalse);
      expect(result.level, SafetyLevel.critical);
      expect(result.shouldBypassAI, isTrue);
    });

    test('detects "hurt myself"', () {
      final result = SafetyFilter.check('I want to hurt myself');
      expect(result.isSafe, isFalse);
      expect(result.level, SafetyLevel.critical);
      expect(result.shouldBypassAI, isTrue);
    });

    test('detects "tự làm hại"', () {
      final result = SafetyFilter.check('Tôi muốn tự làm hại bản thân');
      expect(result.isSafe, isFalse);
      expect(result.level, SafetyLevel.critical);
      expect(result.shouldBypassAI, isTrue);
    });

    test('detects "tự tổn thương"', () {
      final result = SafetyFilter.check('Em hay tự tổn thương mình');
      expect(result.isSafe, isFalse);
      expect(result.level, SafetyLevel.critical);
      expect(result.shouldBypassAI, isTrue);
    });
  });

  group('SafetyFilter.check — Warning (symptoms / mental health)', () {
    test('detects "trầm cảm"', () {
      final result = SafetyFilter.check('Em nghĩ em bị trầm cảm');
      expect(result.isSafe, isFalse);
      expect(result.level, SafetyLevel.warning);
      expect(result.shouldBypassAI, isFalse);
    });

    test('detects "lo âu"', () {
      final result = SafetyFilter.check('Em hay lo âu lắm');
      expect(result.isSafe, isFalse);
      expect(result.level, SafetyLevel.warning);
      expect(result.shouldBypassAI, isFalse);
    });

    test('detects "mất ngủ"', () {
      final result = SafetyFilter.check('Dạo này em mất ngủ quá');
      expect(result.isSafe, isFalse);
      expect(result.level, SafetyLevel.warning);
      expect(result.shouldBypassAI, isFalse);
    });

    test('detects English "anxiety"', () {
      final result = SafetyFilter.check('I have severe anxiety');
      expect(result.isSafe, isFalse);
      expect(result.level, SafetyLevel.warning);
      expect(result.shouldBypassAI, isFalse);
    });

    test('detects "căng thẳng"', () {
      final result = SafetyFilter.check('Em căng thẳng quá');
      expect(result.isSafe, isFalse);
      expect(result.level, SafetyLevel.warning);
      expect(result.shouldBypassAI, isFalse);
    });

    test('detects "chán nản"', () {
      final result = SafetyFilter.check('Em cảm thấy chán nản');
      expect(result.isSafe, isFalse);
      expect(result.level, SafetyLevel.warning);
      expect(result.shouldBypassAI, isFalse);
    });

    test('detects "panic"', () {
      final result = SafetyFilter.check('Em bị panic attack hôm qua');
      expect(result.isSafe, isFalse);
      expect(result.level, SafetyLevel.warning);
      expect(result.shouldBypassAI, isFalse);
    });
  });

  group('SafetyFilter.check — Safe inputs', () {
    test('normal greeting is safe', () {
      final result = SafetyFilter.check('Xin chào, bạn khỏe không?');
      expect(result.isSafe, isTrue);
      expect(result.level, SafetyLevel.safe);
      expect(result.shouldBypassAI, isFalse);
      expect(result.triggeredKeyword, isNull);
    });

    test('asking about meditation is safe', () {
      final result = SafetyFilter.check(
        'Bạn có thể gợi ý meditation cho em không?',
      );
      expect(result.isSafe, isTrue);
      expect(result.level, SafetyLevel.safe);
      expect(result.shouldBypassAI, isFalse);
    });

    test('asking about mood tracking is safe', () {
      final result = SafetyFilter.check(
        'Hôm nay em muốn ghi nhận tâm trạng',
      );
      expect(result.isSafe, isTrue);
      expect(result.level, SafetyLevel.safe);
      expect(result.shouldBypassAI, isFalse);
    });

    test('asking about expert booking is safe', () {
      final result = SafetyFilter.check(
        'Làm sao để đặt lịch với chuyên gia?',
      );
      expect(result.isSafe, isTrue);
      expect(result.level, SafetyLevel.safe);
      expect(result.shouldBypassAI, isFalse);
    });
  });

  group('SafetyFilter.check — Edge cases', () {
    test('empty input returns safe', () {
      final result = SafetyFilter.check('');
      expect(result.isSafe, isTrue);
      expect(result.level, SafetyLevel.safe);
    });

    test('whitespace-only input returns safe', () {
      final result = SafetyFilter.check('   \n\t  ');
      expect(result.isSafe, isTrue);
      expect(result.level, SafetyLevel.safe);
    });

    test('special characters only returns safe', () {
      final result = SafetyFilter.check('!@#\$%^&*()_+-=[]{}|;:\'",.<>?/~`');
      expect(result.isSafe, isTrue);
      expect(result.level, SafetyLevel.safe);
    });

    test('Unicode emoji only returns safe', () {
      final result = SafetyFilter.check('😊🧘‍♀️💙🔥');
      expect(result.isSafe, isTrue);
      expect(result.level, SafetyLevel.safe);
    });

    test('Vietnamese with diacritic variants still triggers', () {
      // "muốn chết" with no diacritics = "muon chet"
      final result = SafetyFilter.check('Toi muon chet day');
      expect(result.isSafe, isFalse);
      expect(result.level, SafetyLevel.critical);
    });

    test('mixed language input works', () {
      final result = SafetyFilter.check(
        'Em feel depression và muốn tự tử',
      );
      expect(result.isSafe, isFalse);
      expect(result.level, SafetyLevel.critical);
    });

    test('long input with embedded keyword', () {
      final longInput = 'A' * 5000 + ' tôi muốn tự tử ' + 'B' * 5000;
      final result = SafetyFilter.check(longInput);
      expect(result.isSafe, isFalse);
      expect(result.level, SafetyLevel.critical);
    });

    test('keyword with extra whitespace still detected', () {
      final result = SafetyFilter.check('Tôi   muốn   tự   tử');
      expect(result.isSafe, isFalse);
      expect(result.level, SafetyLevel.critical);
    });
  });

  group('SafetyFilter — Performance', () {
    test('filter processes in < 50ms', () {
      final input = 'Em đang cảm thấy rất trầm cảm và lo âu';
      final sw = Stopwatch()..start();
      for (var i = 0; i < 100; i++) {
        SafetyFilter.check(input);
      }
      sw.stop();
      final avgMs = sw.elapsedMilliseconds / 100;
      expect(avgMs, lessThan(50),
          reason: 'Average filter time: ${avgMs.toStringAsFixed(2)}ms');
    });

    test('filter does not block event loop (async execution)', () async {
      // Verify the filter runs synchronously and doesn't block
      final input = 'Test input';
      final result = SafetyFilter.check(input);
      expect(result, isNotNull);

      // Ensure other async operations can proceed
      var asyncRan = false;
      Future.delayed(Duration.zero, () {
        asyncRan = true;
      });
      await Future.delayed(Duration(milliseconds: 10));
      expect(asyncRan, isTrue);
    });

    test('filter handles 1000 iterations in < 500ms', () {
      final inputs = List.generate(
        1000,
        (i) => 'Input number $i with some normal text',
      );
      final sw = Stopwatch()..start();
      for (final input in inputs) {
        SafetyFilter.check(input);
      }
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(500),
          reason: '1000 iterations took: ${sw.elapsedMilliseconds}ms');
    });
  });

  group('SafetyFilter — SafetyResult properties', () {
    test('safe result has null emergency message', () {
      const result = SafetyResult.safe();
      expect(result.isSafe, isTrue);
      expect(result.shouldBypassAI, isFalse);
      expect(result.emergencyMessage, isNull);
      expect(result.triggeredKeyword, isNull);
    });

    test('unsafe critical has shouldBypassAI = true', () {
      const result = SafetyResult.unsafe(
        level: SafetyLevel.critical,
        triggeredKeyword: 'test',
        emergencyMessage: 'emergency',
      );
      expect(result.isSafe, isFalse);
      expect(result.shouldBypassAI, isTrue);
      expect(result.emergencyMessage, 'emergency');
    });

    test('unsafe warning has shouldBypassAI = false', () {
      const result = SafetyResult.unsafe(
        level: SafetyLevel.warning,
        triggeredKeyword: 'test',
      );
      expect(result.isSafe, isFalse);
      expect(result.shouldBypassAI, isFalse);
    });
  });
}
