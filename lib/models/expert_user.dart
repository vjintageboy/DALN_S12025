import 'package:cloud_firestore/cloud_firestore.dart';

/// Expert account status
enum ExpertStatus {
  pending,    // Đang chờ duyệt
  approved,   // Đã được duyệt, có thể hoạt động
  active,     // Đang hoạt động
  inactive,   // Tạm ngừng
  rejected,   // Bị từ chối
  suspended   // Bị đình chỉ
}

/// Expert credentials model
class ExpertCredentials {
  final String? licenseNumber;
  final String? licenseUrl;
  final List<String> certificateUrls;
  final String? education;
  final String? university;
  final int? graduationYear;
  final String? specialization;
  final String? bio;

  ExpertCredentials({
    this.licenseNumber,
    this.licenseUrl,
    this.certificateUrls = const [],
    this.education,
    this.university,
    this.graduationYear,
    this.specialization,
    this.bio,
  });

  Map<String, dynamic> toMap() {
    return {
      'licenseNumber': licenseNumber,
      'licenseUrl': licenseUrl,
      'certificateUrls': certificateUrls,
      'education': education,
      'university': university,
      'graduationYear': graduationYear,
      'specialization': specialization,
      'bio': bio,
    };
  }

  factory ExpertCredentials.fromMap(Map<String, dynamic> map) {
    return ExpertCredentials(
      licenseNumber: map['licenseNumber'],
      licenseUrl: map['licenseUrl'],
      certificateUrls: List<String>.from(map['certificateUrls'] ?? []),
      education: map['education'],
      university: map['university'],
      graduationYear: map['graduationYear'],
      specialization: map['specialization'],
      bio: map['bio'],
    );
  }
}

/// Expert User model - extends regular user with expert-specific fields
class ExpertUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final ExpertStatus status;
  final String? expertId; // Link to expert profile in 'experts' collection
  final ExpertCredentials credentials;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? approvedBy; // Admin UID who approved
  final DateTime? rejectedAt;
  final String? rejectedBy; // Admin UID who rejected
  final String? rejectionReason;
  final DateTime? suspendedAt;
  final String? suspendedBy; // Admin UID who suspended
  final String? suspensionReason;
  final DateTime? lastLoginAt;

  ExpertUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.status = ExpertStatus.pending,
    this.expertId,
    required this.credentials,
    DateTime? createdAt,
    this.approvedAt,
    this.approvedBy,
    this.rejectedAt,
    this.rejectedBy,
    this.rejectionReason,
    this.suspendedAt,
    this.suspendedBy,
    this.suspensionReason,
    this.lastLoginAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Getters
  bool get isPending => status == ExpertStatus.pending;
  bool get isApproved => status == ExpertStatus.approved || status == ExpertStatus.active;
  bool get isActive => status == ExpertStatus.active;
  bool get isRejected => status == ExpertStatus.rejected;
  bool get isSuspended => status == ExpertStatus.suspended;
  bool get canLogin => isApproved || isActive;

  String get statusLabel {
    switch (status) {
      case ExpertStatus.pending:
        return 'Pending Approval';
      case ExpertStatus.approved:
        return 'Approved';
      case ExpertStatus.active:
        return 'Active';
      case ExpertStatus.inactive:
        return 'Inactive';
      case ExpertStatus.rejected:
        return 'Rejected';
      case ExpertStatus.suspended:
        return 'Suspended';
    }
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': 'expert', // Always expert role
      'status': status.name,
      'expertId': expertId,
      'credentials': credentials.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'rejectedBy': rejectedBy,
      'rejectionReason': rejectionReason,
      'suspendedAt': suspendedAt != null ? Timestamp.fromDate(suspendedAt!) : null,
      'suspendedBy': suspendedBy,
      'suspensionReason': suspensionReason,
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }

  // Create from Firestore document
  factory ExpertUser.fromMap(Map<String, dynamic> map, String uid) {
    return ExpertUser(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      status: ExpertStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ExpertStatus.pending,
      ),
      expertId: map['expertId'],
      credentials: ExpertCredentials.fromMap(map['credentials'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (map['approvedAt'] as Timestamp?)?.toDate(),
      approvedBy: map['approvedBy'],
      rejectedAt: (map['rejectedAt'] as Timestamp?)?.toDate(),
      rejectedBy: map['rejectedBy'],
      rejectionReason: map['rejectionReason'],
      suspendedAt: (map['suspendedAt'] as Timestamp?)?.toDate(),
      suspendedBy: map['suspendedBy'],
      suspensionReason: map['suspensionReason'],
      lastLoginAt: (map['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  // Create from Firestore DocumentSnapshot
  factory ExpertUser.fromSnapshot(DocumentSnapshot doc) {
    return ExpertUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // Copy with method
  ExpertUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    ExpertStatus? status,
    String? expertId,
    ExpertCredentials? credentials,
    DateTime? createdAt,
    DateTime? approvedAt,
    String? approvedBy,
    DateTime? rejectedAt,
    String? rejectedBy,
    String? rejectionReason,
    DateTime? suspendedAt,
    String? suspendedBy,
    String? suspensionReason,
    DateTime? lastLoginAt,
  }) {
    return ExpertUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      expertId: expertId ?? this.expertId,
      credentials: credentials ?? this.credentials,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      suspendedBy: suspendedBy ?? this.suspendedBy,
      suspensionReason: suspensionReason ?? this.suspensionReason,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  // Static methods for Firestore operations
  static Future<ExpertUser?> getByUid(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('expertUsers')
          .doc(uid)
          .get();
      
      if (!doc.exists) return null;
      return ExpertUser.fromSnapshot(doc);
    } catch (e) {
      print('❌ Error getting expert user: $e');
      return null;
    }
  }

  static Future<List<ExpertUser>> getAllExperts({ExpertStatus? status}) async {
    try {
      Query query = FirebaseFirestore.instance.collection('expertUsers');
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ExpertUser.fromSnapshot(doc))
          .toList();
    } catch (e) {
      print('❌ Error getting all experts: $e');
      return [];
    }
  }

  static Future<List<ExpertUser>> getPendingExperts() async {
    return getAllExperts(status: ExpertStatus.pending);
  }

  static Stream<List<ExpertUser>> streamPendingExperts() {
    return FirebaseFirestore.instance
        .collection('expertUsers')
        .where('status', isEqualTo: ExpertStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpertUser.fromSnapshot(doc))
            .toList());
  }

  static Stream<ExpertUser?> streamExpertUser(String uid) {
    return FirebaseFirestore.instance
        .collection('expertUsers')
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return ExpertUser.fromSnapshot(doc);
        });
  }
}
