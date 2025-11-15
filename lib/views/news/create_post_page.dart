import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/news_post.dart';
import '../../services/news_service.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final NewsService _newsService = NewsService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  
  PostCategory _selectedCategory = PostCategory.community;
  bool _isSubmitting = false;
  bool _postAnonymously = false; // ✅ NEW: Anonymous toggle

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter content')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      
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
        // Get real user info from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        final userData = userDoc.data();
        authorName = userData?['displayName'] ?? user.displayName ?? 'User';
        authorAvatarUrl = user.photoURL;
        authorRole = userData?['role'] ?? 'user';
      }

      final post = NewsPost(
        postId: '',
        authorId: user.uid, // Keep real ID for moderation
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        authorRole: authorRole,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
      );

      await _newsService.createPost(post);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Post created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Create Post',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitPost,
            child: Text(
              'Post',
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
                                selectedColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                                labelStyle: TextStyle(
                                  color: _selectedCategory == category
                                      ? const Color(0xFF6C63FF)
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
                      activeColor: const Color(0xFF6C63FF),
                      secondary: Icon(
                        _postAnonymously ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF6C63FF),
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
