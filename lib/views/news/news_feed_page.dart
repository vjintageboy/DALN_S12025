import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../../models/news_post.dart';
import '../../services/news_service.dart';
import 'create_post_page.dart';
import 'post_detail_page.dart';

class NewsFeedPage extends StatefulWidget {
  const NewsFeedPage({super.key});

  @override
  State<NewsFeedPage> createState() => _NewsFeedPageState();
}

class _NewsFeedPageState extends State<NewsFeedPage> {
  final NewsService _newsService = NewsService();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  
  PostCategory? _selectedCategory;

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
          'Community',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 0,
        actions: [
          // Create post button
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePostPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          _buildCategoryFilter(),
          
          // Posts list
          Expanded(
            child: StreamBuilder<List<NewsPost>>(
              stream: _newsService.streamPosts(category: _selectedCategory),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // Log the actual error for debugging
                  print('❌ Error loading posts: ${snapshot.error}');
                  
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                          const SizedBox(height: 16),
                          const Text(
                            'Error loading posts',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedCategory = null;
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6C63FF),
                    ),
                  );
                }

                final posts = snapshot.data!;

                if (posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No posts yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to share!',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  color: const Color(0xFF6C63FF),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      return _buildPostCard(posts[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildCategoryChip('All', null),
          const SizedBox(width: 8),
          _buildCategoryChip('Mental Health', PostCategory.mentalHealth),
          const SizedBox(width: 8),
          _buildCategoryChip('Meditation', PostCategory.meditation),
          const SizedBox(width: 8),
          _buildCategoryChip('Wellness', PostCategory.wellness),
          const SizedBox(width: 8),
          _buildCategoryChip('Tips', PostCategory.tips),
          const SizedBox(width: 8),
          _buildCategoryChip('Community', PostCategory.community),
          const SizedBox(width: 8),
          _buildCategoryChip('News', PostCategory.news),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, PostCategory? category) {
    final isSelected = _selectedCategory == category;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
        });
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF6C63FF) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      checkmarkColor: const Color(0xFF6C63FF),
    );
  }

  Widget _buildPostCard(NewsPost post) {
    final isLiked = post.isLikedBy(currentUserId);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailPage(post: post),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: post.authorName == 'Anonymous'
                        ? Colors.grey.shade300
                        : const Color(0xFF6C63FF).withValues(alpha: 0.2),
                    backgroundImage: post.authorName != 'Anonymous' && post.authorAvatarUrl != null
                        ? (_isBase64(post.authorAvatarUrl!)
                            ? MemoryImage(base64Decode(post.authorAvatarUrl!))
                            : NetworkImage(post.authorAvatarUrl!)) as ImageProvider
                        : null,
                    child: post.authorName == 'Anonymous'
                        ? Icon(
                            Icons.visibility_off,
                            size: 20,
                            color: Colors.grey.shade700,
                          )
                        : (post.authorAvatarUrl == null
                            ? Text(
                                post.authorName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF6C63FF),
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null),
                  ),
                  const SizedBox(width: 12),
                  // Author info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            if (post.authorRole == 'expert') ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Expert',
                                  style: TextStyle(
                                    fontSize: 10,
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
                          _formatTime(post.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(post.category).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      post.categoryDisplayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getCategoryColor(post.category),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Content preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ),

            // Image
            if (post.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Actions (Like, Comment)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Like button
                  InkWell(
                    onTap: () async {
                      await _newsService.toggleLike(post.postId, currentUserId);
                    },
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.grey.shade600,
                          size: 22,
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
                  const SizedBox(width: 24),
                  // Comment button with real-time count
                  StreamBuilder<List<dynamic>>(
                    stream: _newsService.streamComments(post.postId),
                    builder: (context, commentSnapshot) {
                      final commentCount = commentSnapshot.hasData 
                          ? commentSnapshot.data!.length 
                          : post.commentCount;
                      
                      return Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$commentCount',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const Spacer(),
                  // Share button
                  Icon(
                    Icons.share_outlined,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

  /// Check if string is Base64 encoded
  bool _isBase64(String str) {
    // Base64 strings don't start with http/https
    if (str.startsWith('http://') || str.startsWith('https://')) {
      return false;
    }
    // Try to decode to verify it's valid Base64
    try {
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }
}
