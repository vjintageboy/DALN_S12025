import '../services/supabase_service.dart';

enum ExpertStatus {
  pending, // Đang chờ duyệt
  approved, // Đã được duyệt
  active, // Đang hoạt động
  inactive, // Tạm ngừng
  rejected, // Bị từ chối
  suspended, // Bị đình chỉ
}

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
      'license_number': licenseNumber,
      'license_url': licenseUrl,
      'certificate_urls': certificateUrls,
      'education': education,
      'university': university,
      'graduation_year': graduationYear,
      'specialization': specialization,
      'bio': bio,
    };
  }

  factory ExpertCredentials.fromMap(Map<String, dynamic> map) {
    return ExpertCredentials(
      licenseNumber: map['license_number']?.toString(),
      licenseUrl: map['license_url']?.toString(),
      certificateUrls: _parseList(map['certificate_urls']),
      education: map['education']?.toString(),
      university: map['university']?.toString(),
      graduationYear: int.tryParse(map['graduation_year']?.toString() ?? ''),
      specialization: map['specialization']?.toString(),
      bio: map['bio']?.toString(),
    );
  }

  static List<String> _parseList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data.map((e) => e.toString()).toList();
    return [];
  }
}

class ExpertUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final ExpertStatus status;
  final String? expertId;
  final ExpertCredentials credentials;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final DateTime? rejectedAt;
  final String? rejectedBy;
  final String? rejectionReason;
  final DateTime? suspendedAt;
  final String? suspendedBy;
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

  bool get isPending => status == ExpertStatus.pending;
  bool get isApproved =>
      status == ExpertStatus.approved || status == ExpertStatus.active;
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

  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'status': status.name,
      'is_approved': isApproved,
      'created_at': createdAt.toIso8601String(),
      // Join fields would be in experts table
    };
  }

  factory ExpertUser.fromMap(Map<String, dynamic> map, String uid) {
    final userData = map['users'] as Map<String, dynamic>?;

    return ExpertUser(
      uid: uid,
      email: userData?['email']?.toString() ?? '',
      displayName: userData?['full_name']?.toString() ?? '',
      photoUrl: userData?['avatar_url']?.toString(),
      status: map['is_approved'] == true ? ExpertStatus.active : ExpertStatus.pending,
      expertId: map['id']?.toString(),
      credentials: ExpertCredentials.fromMap(map),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      approvedAt: map['approved_at'] != null ? DateTime.parse(map['approved_at']) : null,
      approvedBy: map['approved_by']?.toString(),
    );
  }

  static Future<ExpertUser?> getByUid(String uid) async {
    final data = await SupabaseService.instance.getExpertById(uid);
    if (data != null) {
      return ExpertUser.fromMap(data, uid);
    }
    return null;
  }

  static Future<List<ExpertUser>> getAllExperts({ExpertStatus? status}) async {
    final data = await SupabaseService.instance.getApprovedExperts();
    final experts = data.map((m) => ExpertUser.fromMap(m, m['id'].toString())).toList();
    if (status != null) {
      return experts.where((e) => e.status == status).toList();
    }
    return experts;
  }
}

