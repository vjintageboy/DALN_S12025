import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:n04_app/ai/tools/tool_definitions.dart';

void main() {
  group('ToolDefinitions', () {
    // Test 1: allTools contains exactly 3 FunctionDeclarations
    test('allTools contains exactly 3 FunctionDeclarations', () {
      final tool = ToolDefinitions.allTools;
      expect(tool.functionDeclarations, isNotNull);
      expect(tool.functionDeclarations!.length, equals(3));
    });

    // Test 2: checkExpertAvailability name
    test('checkExpertAvailability name equals check_expert_availability', () {
      expect(
        ToolDefinitions.checkExpertAvailability.name,
        equals('check_expert_availability'),
      );
    });

    // Test 3: bookSession name
    test('bookSession name equals book_session', () {
      expect(ToolDefinitions.bookSession.name, equals('book_session'));
    });

    // Test 4: generateMonthlyReport name
    test('generateMonthlyReport name equals generate_monthly_report', () {
      expect(
        ToolDefinitions.generateMonthlyReport.name,
        equals('generate_monthly_report'),
      );
    });

    // Test 5: checkExpertAvailability required properties
    test(
        'checkExpertAvailability required properties contains expert_id and date',
        () {
      final required =
          ToolDefinitions.checkExpertAvailability.parameters!.requiredProperties;
      expect(required, isNotNull);
      expect(required, containsAll(['expert_id', 'date']));
    });

    // Test 6: checkExpertAvailability optional field 'duration_minutes' is nullable
    test('checkExpertAvailability duration_minutes is nullable', () {
      final properties =
          ToolDefinitions.checkExpertAvailability.parameters!.properties;
      expect(properties, isNotNull);
      expect(properties!['duration_minutes'], isNotNull);
      expect(properties['duration_minutes']!.nullable, isTrue);
    });

    // Test 7: bookSession required properties
    test('bookSession required properties contains all required fields', () {
      final required = ToolDefinitions.bookSession.parameters!.requiredProperties;
      expect(required, isNotNull);
      expect(
        required,
        containsAll([
          'expert_id',
          'appointment_date',
          'duration_minutes',
          'call_type',
        ]),
      );
    });

    // Test 8: bookSession optional field 'user_notes' is nullable
    test('bookSession user_notes is nullable', () {
      final properties = ToolDefinitions.bookSession.parameters!.properties;
      expect(properties, isNotNull);
      expect(properties!['user_notes'], isNotNull);
      expect(properties['user_notes']!.nullable, isTrue);
    });

    // Test 9: generateMonthlyReport required properties
    test('generateMonthlyReport required properties contains month and year',
        () {
      final required =
          ToolDefinitions.generateMonthlyReport.parameters!.requiredProperties;
      expect(required, isNotNull);
      expect(required, containsAll(['month', 'year']));
    });

    // Test 10: All declarations have non-empty descriptions
    test('all declarations have non-empty descriptions', () {
      expect(
        ToolDefinitions.checkExpertAvailability.description,
        isNotEmpty,
      );
      expect(ToolDefinitions.bookSession.description, isNotEmpty);
      expect(ToolDefinitions.generateMonthlyReport.description, isNotEmpty);
    });

    // Test 11: Schema types are correct
    test('string fields use SchemaType.string', () {
      final availProps =
          ToolDefinitions.checkExpertAvailability.parameters!.properties!;
      expect(availProps['expert_id']!.type, equals(SchemaType.string));
      expect(availProps['date']!.type, equals(SchemaType.string));

      final bookProps = ToolDefinitions.bookSession.parameters!.properties!;
      expect(bookProps['expert_id']!.type, equals(SchemaType.string));
      expect(bookProps['appointment_date']!.type, equals(SchemaType.string));
      expect(bookProps['call_type']!.type, equals(SchemaType.string));
    });

    test('integer fields use SchemaType.integer', () {
      final availProps =
          ToolDefinitions.checkExpertAvailability.parameters!.properties!;
      expect(availProps['duration_minutes']!.type, equals(SchemaType.integer));

      final bookProps = ToolDefinitions.bookSession.parameters!.properties!;
      expect(bookProps['duration_minutes']!.type, equals(SchemaType.integer));

      final reportProps =
          ToolDefinitions.generateMonthlyReport.parameters!.properties!;
      expect(reportProps['month']!.type, equals(SchemaType.integer));
      expect(reportProps['year']!.type, equals(SchemaType.integer));
    });

    // Test 12: allTools is a getter (re-creates instance each call with same declarations)
    test('allTools getter returns new Tool instance each call', () {
      final tool1 = ToolDefinitions.allTools;
      final tool2 = ToolDefinitions.allTools;
      expect(identical(tool1, tool2), isFalse);
      expect(
        tool1.functionDeclarations!.length,
        equals(tool2.functionDeclarations!.length),
      );
      expect(
        tool1.functionDeclarations![0].name,
        equals(tool2.functionDeclarations![0].name),
      );
    });
  });
}
