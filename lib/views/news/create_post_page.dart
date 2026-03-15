import 'package:flutter/material.dart';
import '../../models/news_post.dart';
import '../../services/news_service.dart';
import '../../services/supabase_service.dart';
import '../../core/constants/app_colors.dart';

class CreatePostPage extends StatefulWidget {
  final NewsPost? postToEdit; // ✅ Add optional post for editing

  const CreatePostPage({super.key, this.postToEdit});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final NewsService _newsService = NewsService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  PostCategory _selectedCategory = PostCategory.community;
  bool _isSubmitting = false;
  bool _postAnonymously = false;

  @override
  void initState() {
    super.initState();
    // If editing, populate fields
    if (widget.postToEdit != null) {
      _titleController.text = widget.postToEdit!.title;
      _contentController.text = widget.postToEdit!.content;
      _selectedCategory = widget.postToEdit!.category;
      _postAnonymously = widget.postToEdit!.authorName == 'Anonymous';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter content')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final supabaseService = SupabaseService.instance;
      final user = supabaseService.currentUser!;

      // Determine author info based on anonymous toggle
      String authorName;
      String? authorAvatarUrl;
      String authorRole;

      if (_postAnonymously) {
        // Use anonymous identity
        authorName = 'Anonymous';
        authorAvatarUrl = null;
        authorRole = 'user';
      } else {
        final userData = await supabaseService.client.from('users').select().eq('id', user.id).maybeSingle();

        authorName = userData?['full_name'] ?? 'User';
        authorAvatarUrl = userData?['avatar_url'];
        authorRole = userData?['role'] ?? 'user';
      }

      final post = NewsPost(
        postId: widget.postToEdit?.postId ?? '', // Use existing ID if editing
        authorId: user.id, // Keep real ID for moderation
        isAnonymous: _postAnonymously,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        authorRole: authorRole,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
      );

      // Update or create based on mode
      if (widget.postToEdit != null) {
        // Edit mode - update existing post
        await _newsService.updatePost(post);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Post updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Create mode - create new post
        await _newsService.createPost(post);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Post created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.postToEdit != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          isEditMode ? 'Edit Post' : 'Create Post',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryLight,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitPost,
            child: Text(
              isEditMode ? 'Update' : 'Post',
              style: TextStyle(
                color: _isSubmitting ? Colors.white54 : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category selector
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: PostCategory.values.map((category) {
                              return ChoiceChip(
                                label: Text(_getCategoryName(category)),
                                selected: _selectedCategory == category,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  }
                                },
                                selectedColor: AppColors.primaryLight.withValues(alpha: 0.2),
                                labelStyle: TextStyle(
                                  color: _selectedCategory == category
                                      ? AppColors.primaryLight
                                      : Colors.grey.shade700,
                                  fontWeight: _selectedCategory == category
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Anonymous posting toggle
                  Card(
                    child: SwitchListTile(
                      title: const Text(
                        'Post Anonymously',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Hide your identity from other users',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      value: _postAnonymously,
                      onChanged: (value) {
                        setState(() {
                          _postAnonymously = value;
                        });
                      },
                      activeThumbColor: AppColors.primaryLight,
                      secondary: Icon(
                        _postAnonymously
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title input
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'Enter post title...',
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLength: 100,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Content input
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          labelText: 'Content',
                          hintText: 'Share your thoughts...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 10,
                        maxLength: 2000,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getCategoryName(PostCategory category) {
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
}
