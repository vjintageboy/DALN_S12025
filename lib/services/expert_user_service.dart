import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expert_user.dart';
import '../models/expert.dart';

class ExpertUserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================================
  // EXPERT USER REGISTRATION & AUTHENTICATION
  // ============================================================================

  /// Create new expert user account (signup)
  Future<String?> createExpertUser({
    required String email,
    required String password,
    required String displayName,
    required ExpertCredentials credentials,
  }) async {
    try {
      // 1. Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final uid = userCredential.user!.uid;
      
      // 2. Update display name
      await userCredential.user!.updateDisplayName(displayName);
      
      // 3. Create expert user document
      final expertUser = ExpertUser(
        uid: uid,
        email: email,
        displayName: displayName,
        credentials: credentials,
        status: ExpertStatus.pending, // Start with pending status
      );
      
      await _db.collection('expertUsers').doc(uid).set(expertUser.toMap());
      
      // 4. Create in 'users' collection as regular user (not expert yet)
      //    Role will be upgraded to 'expert' only after admin approval
      await _db.collection('users').doc(uid).set({
        'email': email,
        'displayName': displayName,
        'role': 'user', // Keep as regular user until approved
        'hasExpertApplication': true, // Flag to indicate pending expert application
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Expert user created: $email (Pending Approval - Role: user)');
      return uid;
    } catch (e) {
      print('❌ Error creating expert user: $e');
      rethrow;
    }
  }

  /// Get expert user by UID
  Future<ExpertUser?> getExpertUser(String uid) async {
    try {
      final doc = await _db.collection('expertUsers').doc(uid).get();
      
      if (!doc.exists) return null;
      return ExpertUser.fromSnapshot(doc);
    } catch (e) {
      print('❌ Error getting expert user: $e');
      return null;
    }
  }

  /// Stream expert user (real-time updates)
  Stream<ExpertUser?> streamExpertUser(String uid) {
    return _db
        .collection('expertUsers')
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return ExpertUser.fromSnapshot(doc);
        });
  }

  /// Update expert user
  Future<void> updateExpertUser(String uid, Map<String, dynamic> updates) async {
    try {
      await _db.collection('expertUsers').doc(uid).update(updates);
      print('✅ Expert user updated: $uid');
    } catch (e) {
      print('❌ Error updating expert user: $e');
      rethrow;
    }
  }

  /// Update last login
  Future<void> updateLastLogin(String uid) async {
    try {
      await _db.collection('expertUsers').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error updating last login: $e');
    }
  }

  // ============================================================================
  // ADMIN APPROVAL SYSTEM
  // ============================================================================

  /// Approve expert user (Admin only)
  Future<void> approveExpert({
    required String expertUid,
    required String adminUid,
  }) async {
    try {
      // 1. Update expertUser status
      await _db.collection('expertUsers').doc(expertUid).update({
        'status': ExpertStatus.approved.name,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': adminUid,
      });

      // 2. Get expert user data
      final expertUser = await getExpertUser(expertUid);
      if (expertUser == null) {
        throw Exception('Expert user not found');
      }

      // 3. Create expert profile in 'experts' collection
      final expertId = 'exp_${expertUid.substring(0, 8)}';
      
      final expert = Expert(
        expertId: expertId,
        fullName: expertUser.displayName,
        title: _getTitleFromCredentials(expertUser.credentials),
        specialization: expertUser.credentials.specialization ?? 'General',
        bio: expertUser.credentials.bio ?? 'Mental health professional',
        avatarUrl: expertUser.photoUrl,
        yearsOfExperience: _calculateYearsOfExperience(expertUser.credentials),
        pricePerSession: 150000, // Default price
        availability: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'], // Default availability
        timeSlots: ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00'], // Default time slots
        isAvailable: true,
        licenseNumber: expertUser.credentials.licenseNumber,
      );

      await _db.collection('experts').doc(expertId).set(expert.toMap());

      // 4. Link expert profile to expert user
      await _db.collection('expertUsers').doc(expertUid).update({
        'expertId': expertId,
      });

      // 5. Upgrade user role from 'user' to 'expert' in users collection
      await _db.collection('users').doc(expertUid).update({
        'role': 'expert',
        'expertId': expertId,
        'hasExpertApplication': false, // Clear the pending flag
      });

      print('✅ Expert approved: ${expertUser.email} - Role upgraded to expert');
    } catch (e) {
      print('❌ Error approving expert: $e');
      rethrow;
    }
  }

  /// Reject expert user (Admin only)
  Future<void> rejectExpert({
    required String expertUid,
    required String adminUid,
    String? reason,
  }) async {
    try {
      await _db.collection('expertUsers').doc(expertUid).update({
        'status': ExpertStatus.rejected.name,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': adminUid,
        'rejectionReason': reason,
      });

      print('✅ Expert rejected: $expertUid');
    } catch (e) {
      print('❌ Error rejecting expert: $e');
      rethrow;
    }
  }

  /// Suspend expert user (Admin only)
  Future<void> suspendExpert({
    required String expertUid,
    required String adminUid,
    String? reason,
  }) async {
    try {
      await _db.collection('expertUsers').doc(expertUid).update({
        'status': ExpertStatus.suspended.name,
        'suspendedAt': FieldValue.serverTimestamp(),
        'suspendedBy': adminUid,
        'suspensionReason': reason,
      });

      // Also update expert profile to inactive
      final expertUser = await getExpertUser(expertUid);
      if (expertUser?.expertId != null) {
        await _db.collection('experts').doc(expertUser!.expertId).update({
          'isAvailable': false,
        });
      }

      print('✅ Expert suspended: $expertUid');
    } catch (e) {
      print('❌ Error suspending expert: $e');
      rethrow;
    }
  }

  /// Unsuspend expert user (Admin only)
  Future<void> unsuspendExpert({
    required String expertUid,
    required String adminUid,
  }) async {
    try {
      await _db.collection('expertUsers').doc(expertUid).update({
        'status': ExpertStatus.active.name,
        'suspendedAt': null,
        'suspendedBy': null,
        'suspensionReason': null,
      });

      // Also update expert profile to active
      final expertUser = await getExpertUser(expertUid);
      if (expertUser?.expertId != null) {
        await _db.collection('experts').doc(expertUser!.expertId).update({
          'isAvailable': true,
        });
      }

      print('✅ Expert unsuspended: $expertUid');
    } catch (e) {
      print('❌ Error unsuspending expert: $e');
      rethrow;
    }
  }

  // ============================================================================
  // QUERY METHODS
  // ============================================================================

  /// Get all expert users
  Future<List<ExpertUser>> getAllExpertUsers({ExpertStatus? status}) async {
    try {
      Query query = _db.collection('expertUsers');
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      
      final snapshot = await query.orderBy('createdAt', descending: true).get();
      return snapshot.docs
          .map((doc) => ExpertUser.fromSnapshot(doc))
          .toList();
    } catch (e) {
      print('❌ Error getting all expert users: $e');
      return [];
    }
  }

  /// Get pending experts (for admin approval)
  Future<List<ExpertUser>> getPendingExperts() async {
    return getAllExpertUsers(status: ExpertStatus.pending);
  }

  /// Stream pending experts (real-time)
  Stream<List<ExpertUser>> streamPendingExperts() {
    return _db
        .collection('expertUsers')
        .where('status', isEqualTo: ExpertStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpertUser.fromSnapshot(doc))
            .toList());
  }

  /// Stream all expert users
  Stream<List<ExpertUser>> streamAllExpertUsers() {
    return _db
        .collection('expertUsers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpertUser.fromSnapshot(doc))
            .toList());
  }

  /// Check if user is expert
  Future<bool> isExpert(String uid) async {
    try {
      final doc = await _db.collection('expertUsers').doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Check if expert is approved and can login
  Future<bool> canExpertLogin(String uid) async {
    try {
      final expertUser = await getExpertUser(uid);
      return expertUser?.canLogin ?? false;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  String _getTitleFromCredentials(ExpertCredentials credentials) {
    if (credentials.education?.toLowerCase().contains('phd') ?? false) {
      return 'Dr.';
    } else if (credentials.education?.toLowerCase().contains('master') ?? false) {
      return 'Ms.';
    }
    return 'Mr.';
  }

  int _calculateYearsOfExperience(ExpertCredentials credentials) {
    if (credentials.graduationYear != null) {
      return DateTime.now().year - credentials.graduationYear!;
    }
    return 0;
  }

  // ============================================================================
  // DELETE METHODS
  // ============================================================================

  /// Delete expert user and related data (Admin only)
  Future<void> deleteExpertUser(String uid) async {
    try {
      // Get expert user to find expertId
      final expertUser = await getExpertUser(uid);
      
      // Delete from expertUsers collection
      await _db.collection('expertUsers').doc(uid).delete();
      
      // Delete from users collection
      await _db.collection('users').doc(uid).delete();
      
      // Delete expert profile if exists
      if (expertUser?.expertId != null) {
        await _db.collection('experts').doc(expertUser!.expertId).delete();
      }
      
      // Note: Firebase Auth user should be deleted separately if needed
      print('✅ Expert user deleted: $uid');
    } catch (e) {
      print('❌ Error deleting expert user: $e');
      rethrow;
    }
  }
}
