import 'package:cloud_firestore/cloud_firestore.dart';

enum PostCategory {
  mentalHealth,  // Sức khỏe tâm thần
  meditation,    // Thiền & Mindfulness
  wellness,      // Sức khỏe tổng quát
  tips,          // Mẹo & Lời khuyên
  community,     // Cộng đồng
  news,          // Tin tức
}

class NewsPost {
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String authorRole; // 'user', 'expert', 'admin'
  
  final String title;
  final String content;
  final String? imageUrl;
  final PostCategory category;
  
  final List<String> likedBy; // List of user IDs who liked
  final int commentCount;
  
  final DateTime createdAt;
  final DateTime? updatedAt;

  NewsPost({
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.authorRole,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.category,
    List<String>? likedBy,
    this.commentCount = 0,
    DateTime? createdAt,
    this.updatedAt,
  })  : likedBy = likedBy ?? [],
        createdAt = createdAt ?? DateTime.now();

  // Helper methods
  int get likeCount => likedBy.length;
  
  bool isLikedBy(String userId) => likedBy.contains(userId);

  String get categoryDisplayName {
    switch (category) {
      case PostCategory.mentalHealth:
        return 'Mental Health';
      case PostCategory.meditation:
        return 'Meditation';
      case PostCategory.wellness:
        return 'Wellness';
      case PostCategory.tips:
        return 'Tips';
      case PostCategory.community:
        return 'Community';
      case PostCategory.news:
        return 'News';
    }
  }

  // Firestore conversion
  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'authorRole': authorRole,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'category': category.name,
      'likedBy': likedBy,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory NewsPost.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return NewsPost(
      postId: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      authorAvatarUrl: data['authorAvatarUrl'],
      authorRole: data['authorRole'] ?? 'user',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      category: PostCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => PostCategory.community,
      ),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  NewsPost copyWith({
    String? postId,
    String? authorId,
    String? authorName,
    String? authorAvatarUrl,
    String? authorRole,
    String? title,
    String? content,
    String? imageUrl,
    PostCategory? category,
    List<String>? likedBy,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NewsPost(
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      authorRole: authorRole ?? this.authorRole,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      likedBy: likedBy ?? this.likedBy,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
