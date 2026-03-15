enum Gender { male, female, other }

class UserProfile {
  final String profileId;
  final String userId;
  final String fullName;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final String? avatarUrl;
  final List<dynamic> goals;
  final Map<String, dynamic>? preferences;
  final String? role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.profileId,
    required this.userId,
    required this.fullName,
    this.dateOfBirth,
    this.gender,
    this.avatarUrl,
    this.goals = const [],
    this.preferences,
    this.role,
    this.createdAt,
    this.updatedAt,
  });

  // Convert to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': profileId,
      'full_name': fullName,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender?.toString().split('.').last,
      'avatar_url': avatarUrl,
      'goals': goals,
      'preferences': preferences,
      'role': role,
    };
  }

  // Create from Supabase record
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      profileId: map['id'] ?? '',
      userId: map['id'] ?? '',
      fullName: map['full_name'] ?? '',
      dateOfBirth: map['date_of_birth'] != null
          ? DateTime.parse(map['date_of_birth'])
          : null,
      gender: map['gender'] != null
          ? Gender.values.firstWhere(
              (e) => e.toString().split('.').last == map['gender'],
              orElse: () => Gender.other,
            )
          : null,
      avatarUrl: map['avatar_url'],
      goals: List<dynamic>.from(map['goals'] ?? []),
      preferences: map['preferences'],
      role: map['role'] ?? 'user',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  UserProfile copyWith({
    String? profileId,
    String? userId,
    String? fullName,
    DateTime? dateOfBirth,
    Gender? gender,
    String? avatarUrl,
    List<dynamic>? goals,
    Map<String, dynamic>? preferences,
    String? role,
  }) {
    return UserProfile(
      profileId: profileId ?? this.profileId,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      goals: goals ?? this.goals,
      preferences: preferences ?? this.preferences,
      role: role ?? this.role,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
