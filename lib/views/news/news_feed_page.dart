import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/news_post.dart';
import '../../services/news_service.dart';
import '../../services/supabase_service.dart';
import '../../core/constants/app_colors.dart';
import 'create_post_page.dart';
import 'post_detail_page.dart';

enum SortBy {
  latest, // Mới nhất
  hot, // Hot nhất (likes + comments)
  mostLiked, // Nhiều likes nhất
  mostDiscussed, // Nhiều comments nhất
}

enum AuthorFilter { all, myPosts, expertPosts, anonymous }

class NewsFeedPage extends StatefulWidget {
  const NewsFeedPage({super.key});

  @override
  State<NewsFeedPage> createState() => _NewsFeedPageState();
}

class _NewsFeedPageState extends State<NewsFeedPage> {
  final NewsService _newsService = NewsService();
  late final String currentUserId;
  Map<String, bool>? _optimisticLikeState;
  Map<String, int>? _optimisticLikeCount;
  Set<String>? _likeUpdatingPosts;

  PostCategory? _selectedCategory;
  SortBy _sortBy = SortBy.latest;
  AuthorFilter _authorFilter = AuthorFilter.all;

  @override
  void initState() {
    super.initState();
    currentUserId = SupabaseService.instance.currentUser!.id;
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
      backgroundColor: _kSurface,
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(),
      body: Column(
        children: [
          // Spacer cho glass header (SafeArea top + 72px header)
          SizedBox(height: MediaQuery.of(context).padding.top + 72),
          _buildFilterBar(),
          Expanded(child: _buildPostFeed()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildGlassAppBar() {
    final user = SupabaseService.instance.currentUser;
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: _kSurface.withOpacity(0.80),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 72,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Avatar user hiện tại
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: _kPrimaryContainer,
                        backgroundImage: (user?.userMetadata?['avatar_url'] as String?)?.isNotEmpty == true
                            ? NetworkImage(user!.userMetadata!['avatar_url'] as String)
                            : null,
                        child: (user?.userMetadata?['avatar_url'] as String?)?.isNotEmpty != true
                            ? Icon(Icons.person, size: 20, color: _kPrimary)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Cộng đồng',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _kOnSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.search, color: _kOnSurface),
                        onPressed: () {},
                        splashRadius: 22,
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: _kOnSurface),
                        onPressed: () {},
                        splashRadius: 22,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: _kOnSurface),
                        onPressed: () async {
                          final changed = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreatePostPage(),
                            ),
                          );
                          if (changed == true && mounted) setState(() {});
                        },
                        splashRadius: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return const SizedBox.shrink();
  }

  Widget _buildPostFeed() {
    return StreamBuilder<List<NewsPost>>(
      stream: _newsService.streamPosts(category: _selectedCategory),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Không thể tải bài viết',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _kOnSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: _kOnSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _selectedCategory = null),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: _kOnPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _kPrimary));
        }

        final posts = snapshot.data!;
        final sortedPosts = _sortPosts(posts);

        if (sortedPosts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 80, color: _kSurfaceContainerHighest),
                const SizedBox(height: 16),
                const Text(
                  'Chưa có bài viết nào',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _kOnSurface,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hãy là người đầu tiên chia sẻ!',
                  style: TextStyle(color: _kOnSurfaceVariant),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: _kPrimary,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 120),
            itemCount: sortedPosts.length,
            itemBuilder: (context, index) => _buildPostCard(sortedPosts[index]),
          ),
        );
      },
    );
  }

  /// Sort posts based on selected option
  List<NewsPost> _sortPosts(List<NewsPost> posts) {
    final sorted = List<NewsPost>.from(posts);

    switch (_sortBy) {
      case SortBy.latest:
        // Already sorted by createdAt descending from Firestore
        break;

      case SortBy.hot:
        // Hot = combination of likes and comments (weighted)
        sorted.sort((a, b) {
          final scoreA = (a.likeCount * 2) + a.commentCount;
          final scoreB = (b.likeCount * 2) + b.commentCount;
          return scoreB.compareTo(scoreA);
        });
        break;

      case SortBy.mostLiked:
        sorted.sort((a, b) => b.likeCount.compareTo(a.likeCount));
        break;

      case SortBy.mostDiscussed:
        sorted.sort((a, b) => b.commentCount.compareTo(a.commentCount));
        break;
    }

    return sorted;
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
      selectedColor: AppColors.primaryLight.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryLight : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      checkmarkColor: AppColors.primaryLight,
    );
  }

  Widget _buildSortFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Icon(Icons.sort, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            'Sort by:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<SortBy>(
                  value: _sortBy,
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                  ),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                  onChanged: (SortBy? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _sortBy = newValue;
                      });
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: SortBy.latest,
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          const Text('Latest'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: SortBy.hot,
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 16,
                            color: Colors.orange.shade600,
                          ),
                          const SizedBox(width: 8),
                          const Text('Hot'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: SortBy.mostLiked,
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 16,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(width: 8),
                          const Text('Most Liked'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: SortBy.mostDiscussed,
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble,
                            size: 16,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 8),
                          const Text('Most Discussed'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Icon(Icons.person, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            'Author:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AuthorFilter>(
                  value: _authorFilter,
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                  ),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                  onChanged: (AuthorFilter? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _authorFilter = newValue;
                      });
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: AuthorFilter.all,
                      child: Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          const Text('All'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: AuthorFilter.myPosts,
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_circle,
                            size: 16,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 8),
                          const Text('My Posts'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: AuthorFilter.expertPosts,
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 8),
                          const Text('Expert Posts'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: AuthorFilter.anonymous,
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility_off,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          const Text('Anonymous'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<NewsPost> _filterPostsByAuthor(List<NewsPost> posts) {
    switch (_authorFilter) {
      case AuthorFilter.all:
        return posts;
      case AuthorFilter.myPosts:
        return posts.where((p) => p.authorId == currentUserId).toList();
      case AuthorFilter.expertPosts:
        return posts.where((p) => p.authorRole == 'expert').toList();
      case AuthorFilter.anonymous:
        return posts.where((p) => p.authorName == 'Anonymous').toList();
    }
  }

  /// Filter button that opens a bottom sheet with filter options
  Widget _buildFilterButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: _showFilterSheet,
          icon: Icon(Icons.filter_list, color: Colors.grey.shade700),
          label: const Text('Filters'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade800,
            backgroundColor: Colors.white,
            side: BorderSide(color: Colors.grey.shade300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  /// Show modal bottom sheet with sort + author filters
  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.2,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Reuse existing filter widgets
                          _buildCategoryFilter(),
                          const SizedBox(height: 12),
                          _buildSortFilter(),
                          const SizedBox(height: 12),
                          _buildAuthorFilter(),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    // Reset filters
                                    setState(() {
                                      _selectedCategory = null;
                                      _sortBy = SortBy.latest;
                                      _authorFilter = AuthorFilter.all;
                                    });
                                    Navigator.of(context).pop();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryLight,
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: const Text('Reset'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryLight,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: const Text('Done'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPostCard(NewsPost post) {
    if (post.postId.isEmpty) {
      final isLikedFallback = post.isLikedBy(currentUserId);
      return GestureDetector(
        onTap: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => PostDetailPage(post: post)),
          );

          if (changed == true && mounted) {
            setState(() {});
          }
        },
        child: _buildPostCardContent(post, isLikedFallback, post.likeCount),
      );
    }

    _syncLikeOverridesIfServerCaughtUp(post);
    final isLiked = _likeState[post.postId] ??
        post.isLikedBy(currentUserId);
    final likeCount = _likeCountState[post.postId] ?? post.likeCount;

    return GestureDetector(
      onTap: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (context) => PostDetailPage(post: post)),
        );

        if (changed == true && mounted) {
          setState(() {});
        }
      },
      child: _buildPostCardContent(post, isLiked, likeCount),
    );
  }

  Widget _buildPostCardContent(NewsPost post, bool isLiked, int likeCount) {
    return Container(
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
                        : AppColors.primaryLight.withValues(alpha: 0.2),
                    backgroundImage:
                        post.authorName != 'Anonymous' &&
                            post.authorAvatarUrl != null &&
                            post.authorAvatarUrl!.isNotEmpty
                        ? (_isBase64(post.authorAvatarUrl!)
                                  ? MemoryImage(
                                      base64Decode(post.authorAvatarUrl!),
                                    )
                                  : NetworkImage(post.authorAvatarUrl!))
                              as ImageProvider
                        : null,
                    child: post.authorName == 'Anonymous'
                        ? Icon(
                            Icons.visibility_off,
                            size: 20,
                            color: Colors.grey.shade700,
                          )
                        : (post.authorAvatarUrl == null || post.authorAvatarUrl!.isEmpty
                              ? Text(
                                  post.authorName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primaryLight,
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
                                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Expert',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryLight,
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
                      color: _getCategoryColor(
                        post.category,
                      ).withValues(alpha: 0.1),
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
                  // Menu button (3 dots) - Only show for own posts or admin
                  if (post.authorId == currentUserId)
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      onSelected: (value) => _handlePostAction(value, post),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
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
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
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
                      if (_likeUpdating.contains(post.postId)) return;

                      final previousLiked =
                          _likeState[post.postId] ??
                          post.isLikedBy(currentUserId);
                      final previousCount =
                          _likeCountState[post.postId] ?? post.likeCount;
                      final nextLiked = !previousLiked;
                      final nextCount =
                          nextLiked ? previousCount + 1 : (previousCount - 1);

                      setState(() {
                        _likeUpdating.add(post.postId);
                        _likeState[post.postId] = nextLiked;
                        _likeCountState[post.postId] =
                            nextCount < 0 ? 0 : nextCount;
                      });

                      try {
                        await _newsService.toggleLike(post.postId, currentUserId);
                      } catch (e) {
                        if (!mounted) return;
                        setState(() {
                          _likeState[post.postId] = previousLiked;
                          _likeCountState[post.postId] = previousCount;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Like failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        if (mounted) {
                          setState(() {
                            _likeUpdating.remove(post.postId);
                          });
                        }
                      }
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
                          '$likeCount',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Comment count
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      StreamBuilder<int>(
                        stream: _newsService.streamCommentCount(post.postId),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? post.commentCount;
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
    if (str.isEmpty) return false;
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

  void _syncLikeOverridesIfServerCaughtUp(NewsPost post) {
    if (post.postId.isEmpty) return;

    final optimisticLiked = _likeState[post.postId];
    final optimisticCount = _likeCountState[post.postId];

    if (optimisticLiked == null && optimisticCount == null) return;

    final serverLiked = post.isLikedBy(currentUserId);
    final serverCount = post.likeCount;

    if (optimisticLiked == serverLiked && optimisticCount == serverCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _likeState.remove(post.postId);
          _likeCountState.remove(post.postId);
        });
      });
    }
  }

  Map<String, bool> get _likeState => _optimisticLikeState ??= <String, bool>{};
  Map<String, int> get _likeCountState => _optimisticLikeCount ??= <String, int>{};
  Set<String> get _likeUpdating => _likeUpdatingPosts ??= <String>{};

  /// Handle post menu actions (Edit/Delete)
  void _handlePostAction(String action, NewsPost post) {
    switch (action) {
      case 'edit':
        _editPost(post);
        break;
      case 'delete':
        _deletePost(post);
        break;
    }
  }

  /// Edit post
  Future<void> _editPost(NewsPost post) async {
    // Navigate to edit page (we'll create this)
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => CreatePostPage(postToEdit: post)),
    );

    if (changed == true && mounted) {
      setState(() {});
    }
  }

  /// Delete post with confirmation
  Future<void> _deletePost(NewsPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _newsService.deletePost(post.postId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Post deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting post: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

// Organic Sanctuary color palette
const _kSurface = Color(0xFFDDFFE2);
const _kPrimary = Color(0xFF006B1B);
const _kOnPrimary = Color(0xFFD1FFC8);
const _kOnSurface = Color(0xFF0B361D);
const _kOnSurfaceVariant = Color(0xFF3B6447);
const _kSurfaceContainerLowest = Color(0xFFFFFFFF);
const _kSurfaceContainerHighest = Color(0xFFACECBB);
const _kPrimaryContainer = Color(0xFF76FB7A);
const _kSecondaryContainer = Color(0xFF86FAAC);
const _kOnSecondaryContainer = Color(0xFF005F32);
const _kTertiaryContainer = Color(0xFF11EAFF);
const _kOnTertiaryContainer = Color(0xFF005159);
const _kSurfaceContainerHigh = Color(0xFFB5F0C2);
const _kSurfaceContainer = Color(0xFFBEF5CA);
