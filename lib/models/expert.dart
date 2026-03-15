import '../services/supabase_service.dart';

class Expert {
  final String expertId;
  final String fullName;
  final String title; // Dr., Ms., Mr., etc.
  final String specialization; // Anxiety, Depression, Stress, etc.
  final String bio;
  final String? avatarUrl;
  final double rating;
  final int totalReviews;
  final int yearsOfExperience;
  final double pricePerSession; // Price per session (hourly_rate)
  // Availability is now fetched separately from the expert_availability table
  // via AvailabilityService – no longer stored on the Expert model.
  final bool isAvailable;
  final String? licenseNumber;
  final DateTime createdAt;

  Expert({
    required this.expertId,
    required this.fullName,
    required this.title,
    required this.specialization,
    required this.bio,
    this.avatarUrl,
    this.rating = 0.0,
    this.totalReviews = 0,
    required this.yearsOfExperience,
    required this.pricePerSession,
    this.isAvailable = true,
    this.licenseNumber,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get displayName => '$title $fullName';

  // Convert to Map for Supabase (if needed for update/insert)
  Map<String, dynamic> toMap() {
    return {
      'id': expertId,
      'bio': bio,
      'specialization': specialization,
      'hourly_rate': pricePerSession,
      'rating': rating,
      'is_approved': isAvailable,
      // Metadata like full_name, avatar_url are in 'users' table
    };
  }

  // Create from Supabase map
  factory Expert.fromMap(Map<String, dynamic> map) {
    // Handle Supabase join structure: data['users'] contains name and avatar
    final userData = map['users'] as Map<String, dynamic>?;

    return Expert(
      expertId: map['id']?.toString() ?? '',
      fullName: userData?['full_name']?.toString() ?? 'Unknown Expert',
      title:
          map['title']?.toString() ??
          '', // Title might not be in schema, using empty or default
      specialization: map['specialization']?.toString() ?? 'General',
      bio: map['bio']?.toString() ?? '',
      avatarUrl: userData?['avatar_url']?.toString(),
      rating: double.tryParse(map['rating']?.toString() ?? '0.0') ?? 0.0,
      totalReviews: int.tryParse(map['total_reviews']?.toString() ?? '0') ?? 0,
      yearsOfExperience:
          int.tryParse(map['years_experience']?.toString() ?? '0') ?? 0,
      pricePerSession:
          double.tryParse(map['hourly_rate']?.toString() ?? '0.0') ?? 0.0,
      isAvailable: map['is_approved'] ?? true,
      licenseNumber: map['license_number']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }


  // Get all approved experts from Supabase
  static Future<List<Expert>> getAllExperts() async {
    final data = await SupabaseService.instance.getApprovedExperts();
    final experts = data.map((map) => Expert.fromMap(map)).toList();

    // Sort by rating descending
    experts.sort((a, b) => b.rating.compareTo(a.rating));
    return experts;
  }

  // Get experts by specialization
  static Future<List<Expert>> getExpertsBySpecialization(
    String specialization,
  ) async {
    final allExperts = await getAllExperts();
    return allExperts
        .where(
          (e) => e.specialization.toLowerCase() == specialization.toLowerCase(),
        )
        .toList();
  }

  // Get expert by ID
  static Future<Expert?> getExpertById(String expertId) async {
    final data = await SupabaseService.instance.getExpertById(expertId);
    if (data != null) {
      return Expert.fromMap(data);
    }
    return null;
  }

  // Search experts by name or specialization
  static Future<List<Expert>> searchExperts(String query) async {
    final allExperts = await getAllExperts();
    final lowercaseQuery = query.toLowerCase();

    return allExperts.where((expert) {
      return expert.fullName.toLowerCase().contains(lowercaseQuery) ||
          expert.specialization.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
}
