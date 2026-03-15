import 'package:flutter/foundation.dart';
import 'package:n04_app/dummy_firebase.dart';
import '../models/app_user.dart';

/// ⚠️ CHẠY 1 LẦN ĐỂ TẠO ADMIN ACCOUNT
///
/// Cách sử dụng:
/// 1. Mở main.dart
/// 2. Import file này: import 'scripts/create_admin.dart';
/// 3. Gọi createAdminAccount() trong initState hoặc một button
/// 4. Sau khi tạo xong, XÓA hoặc COMMENT code này đi
///
Future<void> createAdminAccount() async {
  // ⚠️ THAY ĐỔI THÔNG TIN NÀY
  const String adminEmail = 'admin@mindfulmoments.com';
  const String adminPassword = 'Admin@123456'; // Password mạnh
  const String adminDisplayName = 'Admin';

  debugPrint('🔧 Starting admin account creation...');

  try {
    // 1. Thử tạo Firebase Auth user
    debugPrint('📧 Creating Firebase Auth user...');
    UserCredential? credential;

    try {
      credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        debugPrint('⚠️  Email already exists. Trying to sign in...');

        // Try to sign in
        credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );

        if (credential!.user != null) {
          // Update to admin role
          final firestoreService = FirestoreService();
          await firestoreService.updateUserRole(
            credential.user!.uid,
            UserRole.admin,
          );
          debugPrint('✅ Admin role updated for existing user');
        }

        return;
      } else {
        rethrow;
      }
    }

    final user = credential!.user;
    if (user == null) {
      debugPrint('❌ Failed to create Firebase Auth user');
      return;
    }

    // 2. Update display name
    await user.updateDisplayName(adminDisplayName);
    debugPrint('✅ Display name updated');

    // 3. Tạo user document với role ADMIN
    debugPrint('📝 Creating Firestore user document...');
    final firestoreService = FirestoreService();
    await firestoreService.createOrUpdateUser(
      uid: user.uid,
      email: adminEmail,
      displayName: adminDisplayName,
      role: UserRole.admin, // ⭐ SET ADMIN ROLE
    );

    debugPrint('');
    debugPrint('🎉 ═══════════════════════════════════════');
    debugPrint('✅ Admin account created successfully!');
    debugPrint('═══════════════════════════════════════');
    debugPrint('📧 Email: $adminEmail');
    debugPrint('🔑 Password: $adminPassword');
    debugPrint('👤 Display Name: $adminDisplayName');
    debugPrint('🎭 Role: ADMIN');
    debugPrint('');
    debugPrint('⚠️  IMPORTANT:');
    debugPrint('1. Please change password after first login');
    debugPrint('2. Remove or comment out this script from your code');
    debugPrint('3. Never commit credentials to Git');
    debugPrint('═══════════════════════════════════════');
  } catch (e) {
    debugPrint('❌ Error creating admin account: $e');

    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          debugPrint('💡 Email already in use. Try signing in with this email.');
          break;
        case 'weak-password':
          debugPrint('💡 Password is too weak. Use a stronger password.');
          break;
        case 'invalid-email':
          debugPrint('💡 Invalid email format.');
          break;
        default:
          debugPrint('💡 Error code: ${e.code}');
      }
    }
  }
}

/// Migrate existing logged-in user to Firestore
/// Sử dụng khi đã có user trong Firebase Auth nhưng chưa có trong Firestore
Future<void> migrateCurrentUser() async {
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    debugPrint('❌ No user logged in');
    return;
  }

  debugPrint('🔧 Migrating user: ${currentUser.email}');

  try {
    final firestoreService = FirestoreService();

    // Check if user document already exists
    final existingUser = await firestoreService.getUser(currentUser.uid);

    if (existingUser != null) {
      debugPrint('✅ User document already exists');
      debugPrint('Role: ${existingUser.role.value}');
      return;
    }

    // Create user document
    await firestoreService.createOrUpdateUser(
      uid: currentUser.uid,
      email: currentUser.email ?? '',
      displayName: currentUser.displayName ?? 'User',
      photoUrl: currentUser.photoURL,
      role: UserRole.user, // Default role
    );

    debugPrint('✅ User migrated successfully: ${currentUser.email}');
  } catch (e) {
    debugPrint('❌ Migration error: $e');
  }
}
