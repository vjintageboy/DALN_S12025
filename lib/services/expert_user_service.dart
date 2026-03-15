import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';
import '../models/expert_user.dart';

class ExpertUserService {
  static final ExpertUserService instance = ExpertUserService._();
  ExpertUserService._();

  // ============================================================================
  // EXPERT USER REGISTRATION & AUTHENTICATION
  // ============================================================================

  /// Create new expert application (simplified for Supabase)
  Future<void> applyForExpert({
    required String uid,
    required ExpertCredentials credentials,
  }) async {
    try {
      await SupabaseService.instance.client.from('experts').insert({
        'id': uid,
        'bio': credentials.bio,
        'specialization': credentials.specialization,
        'is_approved': false,
      });
      debugPrint('✅ Expert application submitted for: $uid');
    } catch (e) {
      debugPrint('❌ Error applying for expert: $e');
      rethrow;
    }
  }

  /// Get expert user by UID
  Future<ExpertUser?> getExpertUser(String uid) async {
    return ExpertUser.getByUid(uid);
  }

  // ============================================================================
  // ADMIN APPROVAL SYSTEM
  // ============================================================================

  /// Approve expert user (Admin only)
  Future<void> approveExpert({
    required String expertUid,
  }) async {
    try {
      await SupabaseService.instance.client
          .from('experts')
          .update({'is_approved': true})
          .eq('id', expertUid);

      // Upgrade user role in 'users' table
      await SupabaseService.instance.client
          .from('users')
          .update({'role': 'expert'})
          .eq('id', expertUid);

      debugPrint('✅ Expert approved: $expertUid');
    } catch (e) {
      debugPrint('❌ Error approving expert: $e');
      rethrow;
    }
  }

  // Admin management methods
  Future<void> rejectExpert({
    required String expertUid,
    String? reason,
  }) async {
    await SupabaseService.instance.client
        .from('experts')
        .update({
          'is_approved': false,
          'rejection_reason': reason,
        })
        .eq('id', expertUid);
  }

  Future<void> suspendExpert({
    required String expertUid,
    String? reason,
  }) async {
    await SupabaseService.instance.client
        .from('experts')
        .update({
          'is_active': false,
          'suspension_reason': reason,
        })
        .eq('id', expertUid);
  }

  Future<void> unsuspendExpert({
    required String expertUid,
  }) async {
    await SupabaseService.instance.client
        .from('experts')
        .update({
          'is_active': true,
        })
        .eq('id', expertUid);
  }

  Future<List<ExpertUser>> getAllExperts() async {
    final data = await SupabaseService.instance.client
        .from('experts')
        .select('*, users!id(*)');
    
    return List<Map<String, dynamic>>.from(data)
        .map((m) => ExpertUser.fromMap(m, m['id'].toString()))
        .toList();
  }

  Future<List<ExpertUser>> getPendingExperts() async {
    final data = await SupabaseService.instance.client
        .from('experts')
        .select('*, users!id(*)')
        .eq('is_approved', false);
    
    return List<Map<String, dynamic>>.from(data)
        .map((m) => ExpertUser.fromMap(m, m['id'].toString()))
        .toList();
  }
}

