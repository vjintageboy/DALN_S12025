import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Script to populate Supabase with sample expert data.
/// Uses the new `expert_availability` table (one row per available day).
///
/// Day-of-week convention:  0=Sunday, 1=Monday … 6=Saturday
class PopulateExpertsData {
  static final _supabase = Supabase.instance.client;

  // Shorthand: produce expert_availability rows for a set of day indices
  static List<Map<String, dynamic>> _slots(
      String expertId, List<int> days, String start, String end) {
    return days
        .map((d) => {
              'expert_id': expertId,
              'day_of_week': d,
              'start_time': start,
              'end_time': end,
            })
        .toList();
  }

  static Future<void> addSampleExperts() async {
    debugPrint('🚀 Starting to populate experts data...');

    // Each record: experts table row + availability slots
    final sampleExperts = [
      {
        'id': 'expert_001',
        'bio': 'Specialized in anxiety disorders with over 12 years of experience. '
            'Cognitive Behavioral Therapy (CBT) expert helping clients overcome '
            'anxiety, panic attacks, and phobias.',
        'specialization': 'Anxiety',
        'hourly_rate': 80.0,
        'rating': 4.9,
        'total_reviews': 156,
        'years_experience': 12,
        'is_approved': true,
        'license_number': 'PSY-2013-001',
        // avatar / full_name live in `users` table
      },
      {
        'id': 'expert_002',
        'bio': 'Clinical psychologist specializing in depression treatment. '
            'Using evidence-based approaches including CBT, mindfulness, and '
            'solution-focused therapy.',
        'specialization': 'Depression',
        'hourly_rate': 90.0,
        'rating': 4.8,
        'total_reviews': 203,
        'years_experience': 15,
        'is_approved': true,
        'license_number': 'PSY-2010-045',
      },
      {
        'id': 'expert_003',
        'bio': 'Licensed therapist focusing on stress management and work-life balance.',
        'specialization': 'Stress',
        'hourly_rate': 70.0,
        'rating': 4.7,
        'total_reviews': 89,
        'years_experience': 8,
        'is_approved': true,
        'license_number': 'LMFT-2017-089',
      },
      {
        'id': 'expert_004',
        'bio': 'Sleep specialist and behavioral psychologist. Expert in treating insomnia '
            'and sleep disorders through CBT-I.',
        'specialization': 'Sleep',
        'hourly_rate': 85.0,
        'rating': 4.9,
        'total_reviews': 124,
        'years_experience': 10,
        'is_approved': true,
        'license_number': 'PSY-2015-234',
      },
      {
        'id': 'expert_005',
        'bio': 'Marriage and family therapist with expertise in couples counseling.',
        'specialization': 'Relationships',
        'hourly_rate': 95.0,
        'rating': 4.8,
        'total_reviews': 178,
        'years_experience': 14,
        'is_approved': true,
        'license_number': 'LMFT-2011-156',
      },
      {
        'id': 'expert_006',
        'bio': 'Counseling psychologist specializing in social anxiety and GAD.',
        'specialization': 'Anxiety',
        'hourly_rate': 65.0,
        'rating': 4.6,
        'total_reviews': 67,
        'years_experience': 6,
        'is_approved': true,
        'license_number': 'LPC-2019-078',
      },
      {
        'id': 'expert_007',
        'bio': 'Clinical psychologist with expertise in treating major depressive disorder.',
        'specialization': 'Depression',
        'hourly_rate': 85.0,
        'rating': 4.9,
        'total_reviews': 145,
        'years_experience': 11,
        'is_approved': true,
        'license_number': 'PSY-2014-167',
      },
      {
        'id': 'expert_008',
        'bio': 'Stress management expert and organizational psychologist.',
        'specialization': 'Stress',
        'hourly_rate': 75.0,
        'rating': 4.7,
        'total_reviews': 92,
        'years_experience': 9,
        'is_approved': true,
        'license_number': 'PSY-2016-203',
      },
    ];

    // expert_availability rows keyed by expert id
    // day_of_week: 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 0=Sun
    final availabilitySlots = {
      'expert_001': _slots('expert_001', [1, 2, 3, 4, 5], '09:00', '17:00'),
      'expert_002': _slots('expert_002', [1, 3, 5], '09:00', '15:00'),
      'expert_003': _slots('expert_003', [2, 4, 6], '10:00', '16:00'),
      'expert_004': _slots('expert_004', [1, 2, 4, 5], '08:00', '18:00'),
      'expert_005': _slots('expert_005', [3, 4, 5, 6], '09:00', '17:00'),
      'expert_006': _slots('expert_006', [1, 2, 3, 5], '13:00', '17:00'),
      'expert_007': _slots('expert_007', [2, 4, 5, 6], '09:00', '16:00'),
      'expert_008': _slots('expert_008', [1, 3, 4, 5], '08:00', '18:00'),
    };

    try {
      int count = 0;

      for (final expertData in sampleExperts) {
        final expertId = expertData['id'] as String;

        // 1. Upsert expert row
        await _supabase.from('experts').upsert(expertData);

        // 2. Replace availability slots
        await _supabase
            .from('expert_availability')
            .delete()
            .eq('expert_id', expertId);

        final slots = availabilitySlots[expertId] ?? [];
        if (slots.isNotEmpty) {
          await _supabase.from('expert_availability').insert(slots);
        }

        count++;
        debugPrint('✅ Upserted: $expertId [$count/${sampleExperts.length}]');
      }

      debugPrint('');
      debugPrint(
          '🎉 Successfully upserted ${sampleExperts.length} experts to Supabase!');
      debugPrint('');
      debugPrint('📊 Summary:');
      debugPrint('  - Total Experts: ${sampleExperts.length}');
      debugPrint(
        '  - Anxiety: ${sampleExperts.where((e) => e['specialization'] == 'Anxiety').length}',
      );
      debugPrint(
        '  - Depression: ${sampleExperts.where((e) => e['specialization'] == 'Depression').length}',
      );
      debugPrint(
        '  - Stress: ${sampleExperts.where((e) => e['specialization'] == 'Stress').length}',
      );
      debugPrint(
        '  - Sleep: ${sampleExperts.where((e) => e['specialization'] == 'Sleep').length}',
      );
      debugPrint(
        '  - Relationships: ${sampleExperts.where((e) => e['specialization'] == 'Relationships').length}',
      );
      debugPrint('');
    } catch (e) {
      debugPrint('❌ Error adding experts: $e');
    }
  }

  /// Delete all experts (use with caution!).
  static Future<void> clearAllExperts() async {
    debugPrint('🗑️  Deleting all experts...');
    try {
      // Cascade delete will remove expert_availability rows if FK is set up;
      // otherwise delete availability first.
      await _supabase.from('expert_availability').delete().neq('id', '');
      await _supabase.from('experts').delete().neq('id', '');
      debugPrint('✅ All experts deleted');
    } catch (e) {
      debugPrint('❌ Error deleting experts: $e');
    }
  }
}
