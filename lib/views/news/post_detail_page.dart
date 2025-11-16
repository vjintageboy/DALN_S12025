import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/news_post.dart';
import '../../models/post_comment.dart';
import '../../services/news_service.dart';

class PostDetailPage extends StatefulWidget {
  final NewsPost post;

  const PostDetailPage({
    super.key,
    required this.post,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final NewsService _newsService = NewsService();
  final TextEditingController _commentController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _commentAnonymously = false; // Anonymous comment toggle

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      final user = FirebaseAuth.instance.currentUser!;
      
      // Determine user info based on anonymous toggle
      String userName;
      String? userAvatarUrl;
      
      if (_commentAnonymously) {
        userName = 'Anonymous';
        userAvatarUrl = null;
      } else {
        // Get user info
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        final userData = userDoc.data();
        userName = userData?['displayName'] ?? user.displayName ?? 'User';
        userAvatarUrl = user.photoURL;
      }

      final comment = PostComment(
        commentId: '',
        postId: widget.post.postId,
        userId: user.uid, // Keep real ID for moderation
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        content: _commentController.text.trim(),
      );

      await _newsService.addComment(comment);
      
      if (!mounted) return;
      
      _commentController.clear();
      
      // Hide keyboard
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Post',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Post content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post card
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Author info
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: widget.post.authorName == 'Anonymous'
                                  ? Colors.grey.shade300
                                  : const Color(0xFF6C63FF).withValues(alpha: 0.2),
                              backgroundImage: widget.post.authorName != 'Anonymous' && widget.post.authorAvatarUrl != null
                                  ? NetworkImage(widget.post.authorAvatarUrl!)
                                  : null,
                              child: widget.post.authorName == 'Anonymous'
                                  ? Icon(
                                      Icons.visibility_off,
                                      size: 24,
                                      color: Colors.grey.shade700,
                                    )
                                  : (widget.post.authorAvatarUrl == null
                                      ? Text(
                                          widget.post.authorName[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Color(0xFF6C63FF),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        )
                                      : null),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        widget.post.authorName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (widget.post.authorRole == 'expert') ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Expert',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF6C63FF),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatTime(widget.post.createdAt),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(widget.post.category).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.post.categoryDisplayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getCategoryColor(widget.post.category),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Title
                        Text(
                          widget.post.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Content
                        Text(
                          widget.post.content,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade800,
                            height: 1.5,
                          ),
                        ),

                        // Image
                        if (widget.post.imageUrl != null) ...[
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.post.imageUrl!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Actions
                        Row(
                          children: [
                            // Like button
                            StreamBuilder<NewsPost?>(
                              stream: _newsService.streamPosts().map((posts) {
                                return posts.firstWhere(
                                  (p) => p.postId == widget.post.postId,
                                  orElse: () => widget.post,
                                );
                              }),
                              builder: (context, snapshot) {
                                final post = snapshot.data ?? widget.post;
                                final isLiked = post.isLikedBy(currentUserId);

                                return InkWell(
                                  onTap: () async {
                                    await _newsService.toggleLike(
                                      widget.post.postId,
                                      currentUserId,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isLiked
                                          ? Colors.red.withValues(alpha: 0.1)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isLiked ? Icons.favorite : Icons.favorite_border,
                                          color: isLiked ? Colors.red : Colors.grey.shade600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${post.likeCount}',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            // Comment count
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  StreamBuilder<List<PostComment>>(
                                    stream: _newsService.streamComments(widget.post.postId),
                                    builder: (context, snapshot) {
                                      final count = snapshot.data?.length ?? widget.post.commentCount;
                                      return Text(
                                        '$count',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Comments section
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Comments',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<List<PostComment>>(
                          stream: _newsService.streamComments(widget.post.postId),
                          builder: (context, snapshot) {
                            // Show loading only on first load
                            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            // Handle error
                            if (snapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32),
                                child: Center(
                                  child: Text(
                                    'Error loading comments',
                                    style: TextStyle(color: Colors.grey.shade500),
                                  ),
                                ),
                              );
                            }

                            final comments = snapshot.data ?? [];

                            if (comments.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline,
                                        size: 48,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No comments yet',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: comments.length,
                              separatorBuilder: (context, index) => const Divider(height: 24),
                              itemBuilder: (context, index) {
                                final comment = comments[index];
                                return _buildCommentItem(comment);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Comment input
          SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // User avatar - tap to toggle anonymous
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FutureBuilder<User?>(
                      future: Future.value(FirebaseAuth.instance.currentUser),
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _commentAnonymously = !_commentAnonymously;
                            });
                          },
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: _commentAnonymously
                                ? Colors.grey.shade300
                                : const Color(0xFF6C63FF).withValues(alpha: 0.2),
                            backgroundImage: !_commentAnonymously && user?.photoURL != null
                                ? NetworkImage(user!.photoURL!)
                                : null,
                            child: _commentAnonymously
                                ? Icon(Icons.visibility_off, size: 18, color: Colors.grey.shade700)
                                : (user?.photoURL == null
                                    ? Text(
                                        (user?.displayName ?? user?.email ?? 'U')[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Color(0xFF6C63FF),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      )
                                    : null),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Comment input field
                  Expanded(
                    child: FutureBuilder<User?>(
                      future: Future.value(FirebaseAuth.instance.currentUser),
                      builder: (context, userSnapshot) {
                        final user = userSnapshot.data;
                        final userName = user?.displayName ?? 
                                        (user?.email?.split('@')[0] ?? 'User');
                        
                        return Container(
                          constraints: const BoxConstraints(
                            maxHeight: 100,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: _commentAnonymously
                                  ? 'Comment as Anonymous...'
                                  : 'Comment as $userName...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.newline,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Color(0xFF6C63FF),
                      size: 24,
                    ),
                    onPressed: _submitComment,
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(PostComment comment) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: comment.userName == 'Anonymous'
              ? Colors.grey.shade300
              : const Color(0xFF6C63FF).withValues(alpha: 0.2),
          backgroundImage: comment.userName != 'Anonymous' && comment.userAvatarUrl != null
              ? NetworkImage(comment.userAvatarUrl!)
              : null,
          child: comment.userName == 'Anonymous'
              ? Icon(
                  Icons.visibility_off,
                  size: 18,
                  color: Colors.grey.shade700,
                )
              : (comment.userAvatarUrl == null
                  ? Text(
                      comment.userName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                  : null),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(comment.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                comment.content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(PostCategory category) {
    switch (category) {
      case PostCategory.mentalHealth:
        return Colors.blue;
      case PostCategory.meditation:
        return Colors.purple;
      case PostCategory.wellness:
        return Colors.green;
      case PostCategory.tips:
        return Colors.orange;
      case PostCategory.community:
        return Colors.pink;
      case PostCategory.news:
        return Colors.teal;
    }
  }
}
