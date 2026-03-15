import 'package:flutter/foundation.dart';
import 'package:n04_app/dummy_firebase.dart';
import '../models/mood_entry.dart';

/// Script to create 29 consecutive days of mood entries for testing streak calculation
///
/// Usage: Call this function from your app to populate test data
/// Example: createStreakTestData(days: 29)
class StreakTestDataGenerator {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Create consecutive mood entries for testing
  ///
  /// [days] - Number of consecutive days to create (default: 29)
  /// [startDate] - Starting date (default: 29 days ago from today)
  static Future<void> createStreakTestData({
    int days = 29,
    DateTime? startDate,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('❌ No user logged in!');
      return;
    }

    debugPrint('🎭 Creating $days consecutive mood entries for testing...');
    debugPrint('👤 User ID: ${user.uid}');

    // Calculate start date (default: days ago from today)
    final now = DateTime.now();
    final start =
        startDate ?? DateTime(now.year, now.month, now.day - days + 1);

    debugPrint('📅 Start date: ${start.toString().split(' ')[0]}');
    debugPrint('📅 End date: ${now.toString().split(' ')[0]}');
    debugPrint('');

    int successCount = 0;
    int errorCount = 0;

    for (int i = 0; i < days; i++) {
      final date = start.add(Duration(days: i));

      // Random mood level (1-5)
      final moodLevel = (i % 5) + 1; // Cycle through 1,2,3,4,5

      // Random emotions based on mood
      final emotions = _getEmotionsForMood(moodLevel);

      // Random note
      final note = _getNoteForMood(moodLevel, i);

      try {
        final moodEntry = MoodEntry(
          entryId: '', // Firestore will generate
          userId: user.uid,
          moodLevel: moodLevel,
          note: note,
          emotionFactors: emotions,
          tags: ['test_data'],
          timestamp: DateTime(
            date.year,
            date.month,
            date.day,
            12, // Set to noon
            0,
            0,
          ),
        );

        final docRef = _db.collection('moodEntries').doc();
        final entryWithId = MoodEntry(
          entryId: docRef.id,
          userId: moodEntry.userId,
          moodLevel: moodEntry.moodLevel,
          note: moodEntry.note,
          timestamp: moodEntry.timestamp,
          emotionFactors: moodEntry.emotionFactors,
          tags: moodEntry.tags,
        );

        await docRef.set(entryWithId.toMap());

        successCount++;
        debugPrint(
          '✅ Day ${i + 1}/$days: ${date.toString().split(' ')[0]} - Mood: ${_getMoodEmoji(moodLevel)} ($moodLevel)',
        );
      } catch (e) {
        errorCount++;
        debugPrint(
          '❌ Day ${i + 1}/$days: ${date.toString().split(' ')[0]} - Error: $e',
        );
      }
    }

    debugPrint('');
    debugPrint('🎉 Test data creation completed!');
    debugPrint('✅ Success: $successCount entries');
    if (errorCount > 0) {
      debugPrint('❌ Errors: $errorCount entries');
    }
    debugPrint('');
    debugPrint('💡 Now open Streak History to see the results!');
    debugPrint('   Expected: Current Streak = $days, Longest Streak = $days');
  }

  /// Delete all test data (mood entries with 'test_data' tag)
  static Future<void> deleteTestData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('❌ No user logged in!');
      return;
    }

    debugPrint('🗑️  Deleting test data...');

    try {
      final snapshot = await _db
          .collection('moodEntries')
          .where('userId', isEqualTo: user.uid)
          .where('tags', arrayContains: 'test_data')
          .get();

      int deleteCount = 0;
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
        deleteCount++;
      }

      debugPrint('✅ Deleted $deleteCount test entries');
    } catch (e) {
      debugPrint('❌ Error deleting test data: $e');
    }
  }

  /// Delete ALL mood entries for current user (DANGER!)
  static Future<void> deleteAllMoodEntries() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('❌ No user logged in!');
      return;
    }

    debugPrint('⚠️  WARNING: Deleting ALL mood entries for user ${user.uid}...');

    try {
      final snapshot = await _db
          .collection('moodEntries')
          .where('userId', isEqualTo: user.uid)
          .get();

      int deleteCount = 0;
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
        deleteCount++;
      }

      debugPrint('✅ Deleted $deleteCount entries');

      // Also reset streak
      await _db.collection('streaks').doc(user.uid).set({
        'streakId': user.uid,
        'userId': user.uid,
        'currentStreak': 0,
        'longestStreak': 0,
        'lastActivityDate': null,
        'totalActivities': 0,
      });

      debugPrint('✅ Streak reset to 0');
    } catch (e) {
      debugPrint('❌ Error deleting entries: $e');
    }
  }

  // Helper methods
  static List<String> _getEmotionsForMood(int moodLevel) {
    switch (moodLevel) {
      case 1:
        return ['Work', 'Sleep', 'Health'];
      case 2:
        return ['Work', 'Relationships'];
      case 3:
        return ['Sleep', 'Food'];
      case 4:
        return ['Exercise', 'Social'];
      case 5:
        return ['Family', 'Health', 'Exercise'];
      default:
        return [];
    }
  }

  static String _getNoteForMood(int moodLevel, int dayIndex) {
    final notes = {
      1: ['Feeling stressed today', 'Not a great day', 'Struggling with work'],
      2: ['Could be better', 'Feeling a bit down', 'Tired and unmotivated'],
      3: ['Average day', 'Nothing special', 'Just okay'],
      4: ['Good day overall!', 'Feeling positive', 'Things are going well'],
      5: [
        'Amazing day! 🎉',
        'Feeling fantastic!',
        'Everything is perfect today!',
      ],
    };

    final moodNotes = notes[moodLevel] ?? ['Test note'];
    return '${moodNotes[dayIndex % moodNotes.length]} (Day ${dayIndex + 1})';
  }

  static String _getMoodEmoji(int moodLevel) {
    switch (moodLevel) {
      case 1:
        return '😞';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }

  /// Create a custom streak pattern for testing
  ///
  /// Example: Create 10 days, skip 2, create 5 days
  static Future<void> createCustomStreakPattern({
    required List<int> pattern,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('❌ No user logged in!');
      return;
    }

    debugPrint('🎭 Creating custom streak pattern: $pattern');

    final now = DateTime.now();
    int dayOffset = 0;

    for (int i = 0; i < pattern.length; i++) {
      final daysToCreate = pattern[i];

      if (i % 2 == 0) {
        // Create entries
        debugPrint('✅ Creating $daysToCreate consecutive days...');
        for (int j = 0; j < daysToCreate; j++) {
          final date = now.subtract(Duration(days: dayOffset));

          final moodEntry = MoodEntry(
            entryId: '',
            userId: user.uid,
            moodLevel: 4,
            note: 'Pattern day ${dayOffset + 1}',
            emotionFactors: ['Health', 'Exercise'],
            tags: ['test_data', 'pattern'],
            timestamp: DateTime(date.year, date.month, date.day, 12, 0, 0),
          );

          final docRef = _db.collection('moodEntries').doc();
          await docRef.set(moodEntry.copyWith(entryId: docRef.id).toMap());

          dayOffset++;
        }
      } else {
        // Skip days
        debugPrint('⏭️  Skipping $daysToCreate days...');
        dayOffset += daysToCreate;
      }
    }

    debugPrint('🎉 Custom pattern created!');
  }
}

// Extension method for MoodEntry
extension MoodEntryCopy on MoodEntry {
  MoodEntry copyWith({
    String? entryId,
    String? userId,
    int? moodLevel,
    String? note,
    DateTime? timestamp,
    List<String>? emotionFactors,
    List<String>? tags,
  }) {
    return MoodEntry(
      entryId: entryId ?? this.entryId,
      userId: userId ?? this.userId,
      moodLevel: moodLevel ?? this.moodLevel,
      note: note ?? this.note,
      timestamp: timestamp ?? this.timestamp,
      emotionFactors: emotionFactors ?? this.emotionFactors,
      tags: tags ?? this.tags,
    );
  }
}
