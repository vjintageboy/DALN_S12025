import 'package:google_generative_ai/google_generative_ai.dart';

class ToolDefinitions {
  static Tool get allTools => Tool(functionDeclarations: [
        checkExpertAvailability,
        bookSession,
        generateMonthlyReport,
      ]);

  static final FunctionDeclaration checkExpertAvailability =
      FunctionDeclaration(
    'check_expert_availability',
    'Kiểm tra các khung giờ trống của chuyên gia trong một ngày cụ thể',
    Schema(SchemaType.object, properties: {
      'expert_id':
          Schema(SchemaType.string, description: 'UUID của chuyên gia'),
      'date': Schema(SchemaType.string,
          description: 'ISO8601 date (YYYY-MM-DD)'),
      'duration_minutes': Schema(SchemaType.integer,
          description: '30 hoặc 60', nullable: true),
    }, requiredProperties: [
      'expert_id',
      'date'
    ]),
  );

  static final FunctionDeclaration bookSession = FunctionDeclaration(
    'book_session',
    'Đặt lịch hẹn với chuyên gia tâm lý',
    Schema(SchemaType.object, properties: {
      'expert_id': Schema(SchemaType.string),
      'appointment_date':
          Schema(SchemaType.string, description: 'ISO8601 datetime'),
      'duration_minutes':
          Schema(SchemaType.integer, description: '30 hoặc 60'),
      'call_type':
          Schema(SchemaType.string, description: 'voice hoặc video'),
      'user_notes': Schema(SchemaType.string, nullable: true),
    }, requiredProperties: [
      'expert_id',
      'appointment_date',
      'duration_minutes',
      'call_type'
    ]),
  );

  static final FunctionDeclaration generateMonthlyReport = FunctionDeclaration(
    'generate_monthly_report',
    'Sinh báo cáo tâm lý tháng: mood trends, appointments, streak',
    Schema(SchemaType.object, properties: {
      'month': Schema(SchemaType.integer, description: '1-12'),
      'year': Schema(SchemaType.integer, description: 'Năm 4 chữ số'),
    }, requiredProperties: [
      'month',
      'year'
    ]),
  );
}
