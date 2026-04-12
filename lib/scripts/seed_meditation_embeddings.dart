import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:n04_app/services/rag_service.dart';

/// Script để seed embedding cho toàn bộ meditation chưa có embedding.
///
/// Cách chạy:
///   flutter run -d <device> --target lib/scripts/seed_meditation_embeddings.dart
///
/// Sau khi chạy xong, bạn có thể xóa script này hoặc giữ lại để re-seed khi cần.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  print('🌱 Starting Meditation Embedding Seeder...');
  print('');

  // ── Authenticate first (required for RLS policies) ──
  // Dùng account có role = 'admin' để bypass RLS khi seed.
  // Nếu chưa có admin, bạn cần sign up/sign in trước.
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) {
    print('⚠️  No active session. Please sign in first.');
    print('   Option 1: Sign in manually in the app, then run this script.');
    print('   Option 2: Use Supabase Dashboard SQL Editor to run:');
    print('     UPDATE meditations SET embedding = NULL;');
    print('   Then call RAGService().seedMeditationEmbeddings() from app code.');
    print('');

    // Try to continue anyway — may work if RLS allows anon read
    print('🔄 Attempting without authentication...');
  } else {
    final user = Supabase.instance.client.auth.currentUser;
    print('👤 Signed in as: ${user?.email ?? user?.id}');
  }

  print('');
  final rag = RAGService();
  final count = await rag.seedMeditationEmbeddings();

  print('');
  print('✅ Done! Successfully seeded $count meditation(s).');
  print('');

  // Verify results
  final client = Supabase.instance.client;
  final result = await client
      .from('meditations')
      .select('id, title')
      .isFilter('embedding', null);

  if (result is List && result.isEmpty) {
    print('🎉 All meditations now have embeddings!');
  } else if (result is List) {
    print('⚠️  ${result.length} meditation(s) still missing embeddings:');
    for (final row in result) {
      print('   - ${row['title']}');
    }
  }

  // Exit the app
  // ignore: deprecated_member_use
  await Supabase.instance.client.dispose();
}
