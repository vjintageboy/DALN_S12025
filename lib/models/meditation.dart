

enum MeditationCategory { stress, anxiety, sleep, focus }

// MeditationLevel không có trong DB nhưng giữ lại cho UI
enum MeditationLevel { beginner, intermediate, advanced }

class Meditation {
  final String meditationId;
  final String title;
  final String description;
  final int duration; // DB: duration_minutes
  final MeditationCategory category;
  final MeditationLevel level; // Không có trong DB, dùng mặc định
  final String? audioUrl;     // DB: audio_url
  final String? thumbnailUrl; // DB: thumbnail_url
  final double rating;        // Không có trong DB, mặc định 0
  final int totalReviews;     // Không có trong DB, mặc định 0

  Meditation({
    required this.meditationId,
    required this.title,
    required this.description,
    required this.duration,
    required this.category,
    this.level = MeditationLevel.beginner,
    this.audioUrl,
    this.thumbnailUrl,
    this.rating = 0.0,
    this.totalReviews = 0,
  });

  /// Convert sang Map để INSERT vào Supabase
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'duration_minutes': duration,
      'category': category.toString().split('.').last,
      'audio_url': audioUrl,
      'thumbnail_url': thumbnailUrl,
    };
  }

  /// Parse từ row Supabase (hỗ trợ cả camelCase cũ)
  factory Meditation.fromMap(Map<String, dynamic> map) {
    return Meditation(
      meditationId: map['id'] ?? map['meditationId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      duration: map['duration_minutes'] ?? map['duration'] ?? 0,
      category: MeditationCategory.values.firstWhere(
        (e) => e.toString().split('.').last == map['category'],
        orElse: () => MeditationCategory.stress,
      ),
      level: MeditationLevel.values.firstWhere(
        (e) => e.toString().split('.').last == (map['level'] ?? ''),
        orElse: () => MeditationLevel.beginner,
      ),
      audioUrl: map['audio_url'] ?? map['audioUrl'],
      thumbnailUrl: map['thumbnail_url'] ?? map['thumbnailUrl'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalReviews: map['total_reviews'] ?? map['totalReviews'] ?? 0,
    );
  }



  /// Update rating (dùng trong UI)
  Meditation updateRating(double newRating) {
    final totalRating = rating * totalReviews + newRating;
    final newTotalReviews = totalReviews + 1;
    return copyWith(
      rating: totalRating / newTotalReviews,
      totalReviews: newTotalReviews,
    );
  }

  Meditation copyWith({
    String? meditationId,
    String? title,
    String? description,
    int? duration,
    MeditationCategory? category,
    MeditationLevel? level,
    String? audioUrl,
    String? thumbnailUrl,
    double? rating,
    int? totalReviews,
  }) {
    return Meditation(
      meditationId: meditationId ?? this.meditationId,
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      level: level ?? this.level,
      audioUrl: audioUrl ?? this.audioUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
    );
  }
}
