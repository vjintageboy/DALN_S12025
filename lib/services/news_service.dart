import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_post.dart';
import '../models/post_comment.dart';

class NewsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== POSTS ====================

  /// Stream all posts, ordered by createdAt descending
  Stream<List<NewsPost>> streamPosts({PostCategory? category}) {
    try {
      Query query;
      
      if (category != null) {
        // Server-side filtering with composite index (now enabled!)
        query = _db.collection('newsPosts')
            .where('category', isEqualTo: category.name)
            .orderBy('createdAt', descending: true);
      } else {
        // No filter, just orderBy
        query = _db.collection('newsPosts')
            .orderBy('createdAt', descending: true);
      }

      return query.snapshots().handleError((error) {
        debugPrint('❌ Error streaming posts: $error');
        throw Exception('Failed to load posts: $error');
      }).map((snapshot) {
        return snapshot.docs.map((doc) => NewsPost.fromSnapshot(doc)).toList();
      });
    } catch (e) {
      debugPrint('❌ Error creating query: $e');
      rethrow;
    }
  }

  /// Get single post by ID
  Future<NewsPost?> getPost(String postId) async {
    try {
      final doc = await _db.collection('newsPosts').doc(postId).get();
      if (doc.exists) {
        return NewsPost.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting post: $e');
      return null;
    }
  }

  /// Create new post
  Future<String?> createPost(NewsPost post) async {
    try {
      final docRef = _db.collection('newsPosts').doc();
      final newPost = post.copyWith(
        postId: docRef.id,
        createdAt: DateTime.now(),
      );
      
      await docRef.set(newPost.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating post: $e');
      rethrow;
    }
  }

  /// Update post
  Future<void> updatePost(NewsPost post) async {
    try {
      await _db.collection('newsPosts').doc(post.postId).update(
        post.copyWith(updatedAt: DateTime.now()).toMap(),
      );
    } catch (e) {
      debugPrint('Error updating post: $e');
      rethrow;
    }
  }

  /// Delete post (and its comments)
  Future<void> deletePost(String postId) async {
    try {
      // Delete all comments first
      final commentsSnapshot = await _db
          .collection('postComments')
          .where('postId', isEqualTo: postId)
          .get();

      final batch = _db.batch();
      for (final doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the post
      batch.delete(_db.collection('newsPosts').doc(postId));
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting post: $e');
      rethrow;
    }
  }

  // ==================== LIKES ====================

  /// Toggle like on a post
  Future<void> toggleLike(String postId, String userId) async {
    try {
      final postRef = _db.collection('newsPosts').doc(postId);
      final postDoc = await postRef.get();
      
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final post = NewsPost.fromSnapshot(postDoc);
      final likedBy = List<String>.from(post.likedBy);

      if (likedBy.contains(userId)) {
        // Unlike
        likedBy.remove(userId);
      } else {
        // Like
        likedBy.add(userId);
      }

      await postRef.update({'likedBy': likedBy});
    } catch (e) {
      debugPrint('Error toggling like: $e');
      rethrow;
    }
  }

  // ==================== COMMENTS ====================

  /// Stream comments for a post
  Stream<List<PostComment>> streamComments(String postId) {
    return _db
        .collection('postComments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .handleError((error) {
          debugPrint('Error streaming comments: $error');
          return <PostComment>[];
        })
        .map((snapshot) {
      return snapshot.docs.map((doc) => PostComment.fromSnapshot(doc)).toList();
    });
  }

  /// Add comment to post
  Future<void> addComment(PostComment comment) async {
    try {
      final docRef = _db.collection('postComments').doc();
      final newComment = PostComment(
        commentId: docRef.id,
        postId: comment.postId,
        userId: comment.userId,
        userName: comment.userName,
        userAvatarUrl: comment.userAvatarUrl,
        content: comment.content,
        createdAt: DateTime.now(),
      );

      // Add comment
      await docRef.set(newComment.toMap());

      // Increment comment count
      await _db.collection('newsPosts').doc(comment.postId).update({
        'commentCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  /// Delete comment
  Future<void> deleteComment(String commentId, String postId) async {
    try {
      await _db.collection('postComments').doc(commentId).delete();

      // Decrement comment count
      await _db.collection('newsPosts').doc(postId).update({
        'commentCount': FieldValue.increment(-1),
      });
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      rethrow;
    }
  }

  // ==================== UTILITY ====================

  /// Get user's posts
  Future<List<NewsPost>> getUserPosts(String userId) async {
    try {
      final snapshot = await _db
          .collection('newsPosts')
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => NewsPost.fromSnapshot(doc)).toList();
    } catch (e) {
      debugPrint('Error getting user posts: $e');
      return [];
    }
  }
}

void debugPrint(String message) {
  print(message);
}
