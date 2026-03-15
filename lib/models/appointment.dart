

enum CallType {
  voice, // 📞 Voice Call
  video, // 🎥 Video Call
}

enum AppointmentStatus {
  pending, // Chờ xác nhận
  confirmed, // Đã xác nhận
  completed, // Đã hoàn thành
  cancelled, // Đã hủy
}

enum RefundStatus {
  none, // Không có hoàn tiền
  pending, // Đang xử lý
  success, // Đã hoàn tiền
  failed, // Hoàn tiền thất bại
}

class Appointment {
  final String appointmentId;
  final String userId;
  final String expertId;
  final String expertName;
  final String? expertAvatarUrl;
  final double expertBasePrice; 

  final String? userName;
  final String? userAvatarUrl;

  final CallType callType;
  final DateTime appointmentDate;
  final int durationMinutes;

  final AppointmentStatus status;
  final String? userNotes;

  final DateTime createdAt;
  final DateTime? cancelledAt;
  final String? cancelledBy; 
  final String? cancelledRole;
  final String? cancellationReason; 
  final String? paymentId; 
  final String? paymentTransId; 
  final RefundStatus refundStatus;

  Appointment({
    required this.appointmentId,
    required this.userId,
    required this.expertId,
    required this.expertName,
    this.expertAvatarUrl,
    required this.expertBasePrice,
    required this.callType,
    required this.appointmentDate,
    required this.durationMinutes,
    this.status = AppointmentStatus.confirmed,
    this.userNotes,
    this.userName,
    this.userAvatarUrl,
    DateTime? createdAt,
    this.cancelledAt,
    this.cancelledBy,
    this.cancelledRole,
    this.cancellationReason,
    this.paymentId,
    this.paymentTransId,
    this.refundStatus = RefundStatus.none,
  }) : createdAt = createdAt ?? DateTime.now();

  double get price {
    return calculatePrice(
      expertBasePrice: expertBasePrice,
      callType: callType,
      duration: durationMinutes,
    );
  }

  String get callTypeLabel {
    return callType == CallType.voice ? '📞 Voice Call' : '🎥 Video Call';
  }

  String get callTypeIcon {
    return callType == CallType.voice ? '📞' : '🎥';
  }

  bool get isPending => status == AppointmentStatus.pending;
  bool get isConfirmed => status == AppointmentStatus.confirmed;
  bool get isCompleted => status == AppointmentStatus.completed;
  bool get isCancelled => status == AppointmentStatus.cancelled;

  bool get canCancel {
    if (status != AppointmentStatus.confirmed) return false;
    final now = DateTime.now();
    final hoursDiff = appointmentDate.difference(now).inHours;
    return hoursDiff >= 4;
  }

  DateTime get endTime {
    return appointmentDate.add(Duration(minutes: durationMinutes));
  }

  static double calculatePrice({
    required double expertBasePrice,
    required CallType callType,
    required int duration,
  }) {
    double finalPrice = expertBasePrice;
    if (callType == CallType.voice) {
      finalPrice = finalPrice * 0.67;
    }
    if (duration == 30) {
      finalPrice = finalPrice * 0.5;
    }
    return finalPrice;
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'expert_id': expertId,
      'appointment_date': appointmentDate.toIso8601String(),
      'duration_minutes': durationMinutes,
      'status': status.name,
      'user_notes': userNotes,
      'payment_id': paymentId,
      // Metadata fields not directly in the simple appointments table might need handling
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    // Handle join with experts/users if provided (Expert info)
    final expertData = map['experts'] as Map<String, dynamic>?;
    final expertUserData = expertData?['users'] as Map<String, dynamic>?;

    // Handle join with users if provided (Patient info)
    // In some queries it might be 'users' or 'users!user_id'
    final patientData =
        (map['users'] ?? map['users!user_id']) as Map<String, dynamic>?;

    return Appointment(
      appointmentId: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      expertId: map['expert_id']?.toString() ?? '',
      expertName: expertUserData?['full_name']?.toString() ??
          map['expert_name']?.toString() ??
          'Expert',
      expertAvatarUrl: expertUserData?['avatar_url']?.toString() ??
          map['expert_avatar_url']?.toString(),
      expertBasePrice: double.tryParse(map['expert_base_price']?.toString() ??
              expertData?['hourly_rate']?.toString() ??
              '150000.0') ??
          150000.0,
      callType: _parseCallType(map['call_type']?.toString()),
      appointmentDate: map['appointment_date'] != null
          ? DateTime.parse(map['appointment_date'])
          : DateTime.now(),
      durationMinutes: map['duration_minutes'] ?? 60,
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AppointmentStatus.confirmed,
      ),
      userNotes: map['user_notes'],
      userName: patientData?['full_name']?.toString(),
      userAvatarUrl: patientData?['avatar_url']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      cancelledAt: map['cancelled_at'] != null
          ? DateTime.parse(map['cancelled_at'])
          : null,
        cancelledBy: map['cancelled_by']?.toString(),
        cancelledRole: map['cancelled_role']?.toString(),
      cancellationReason: map['cancellation_reason'],
      paymentId: map['payment_id'],
      paymentTransId: map['payment_trans_id'],
      refundStatus: RefundStatus.values.firstWhere(
        (e) => e.name == (map['refund_status'] ?? 'none'),
        orElse: () => RefundStatus.none,
      ),
    );
  }

  Appointment copyWith({
    String? appointmentId,
    String? expertId,
    AppointmentStatus? status,
    DateTime? cancelledAt,
    String? cancelledBy,
    String? cancelledRole,
    String? cancellationReason,
    String? paymentId,
    String? paymentTransId,
    RefundStatus? refundStatus,
    String? userName,
    String? userAvatarUrl,
  }) {
    return Appointment(
      appointmentId: appointmentId ?? this.appointmentId,
      userId: userId,
      expertId: expertId ?? this.expertId,
      expertName: expertName,
      expertAvatarUrl: expertAvatarUrl,
      expertBasePrice: expertBasePrice,
      callType: callType,
      appointmentDate: appointmentDate,
      durationMinutes: durationMinutes,
      status: status ?? this.status,
      userNotes: userNotes,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      createdAt: createdAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancelledRole: cancelledRole ?? this.cancelledRole,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      paymentId: paymentId ?? this.paymentId,
      paymentTransId: paymentTransId ?? this.paymentTransId,
      refundStatus: refundStatus ?? this.refundStatus,
    );
  }

  static CallType _parseCallType(String? dbValue) {
    // Backward compatibility with DB enum values:
    // - chat => voice
    // - video => video
    if (dbValue == 'chat' || dbValue == 'voice') return CallType.voice;
    return CallType.video;
  }
}
