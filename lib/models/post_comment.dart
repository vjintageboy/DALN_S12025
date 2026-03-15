class PostComment {
  final String commentId;
  final String postId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String content;
  final DateTime createdAt;

  PostComment({
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.content,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
    
    if (commentId.isNotEmpty) {
      map['id'] = commentId;
    }
    
    return map;
  }

  factory PostComment.fromMap(Map<String, dynamic> data) {
    // Check if author data is joined
    final users = data['users'] as Map<String, dynamic>?;
    final userName = users?['full_name'] ?? 'Unknown';
    final userAvatarUrl = users?['avatar_url'];

    return PostComment(
      commentId: data['id'] ?? '',
      postId: data['post_id'] ?? '',
      userId: data['user_id'] ?? '',
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      content: data['content'] ?? '',
      createdAt: data['created_at'] != null 
          ? DateTime.parse(data['created_at']).toLocal() 
          : DateTime.now(),
    );
  }
}

