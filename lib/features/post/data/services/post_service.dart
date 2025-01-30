// services/post_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_function_testing/features/post/data/models/post.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostService {
  final _db = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instance;
  final _auth = FirebaseAuth.instance;

  // Menggunakan Firestore langsung untuk get posts
  Future<List<Post>> getPosts() async {
    try {
      final snapshot = await _db
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Post.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get posts: $e');
    }
  }

  // Tetap menggunakan Cloud Function untuk create (dengan filter)
  Future<void> createPost(String content) async {
    try {
      await _functions.httpsCallable('createFilteredPost').call({
        'content': content,
      });
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  // Menggunakan Firestore langsung untuk delete
  Future<void> deletePost(String postId) async {
    try {
      final doc = await _db.collection('posts').doc(postId).get();
      if (doc.data()?['userId'] != _auth.currentUser?.uid) {
        throw Exception('Not authorized to delete this post');
      }
      await doc.reference.delete();
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // Tetap menggunakan Cloud Function untuk comment (dengan filter)
  Future<void> addComment(String postId, String content) async {
    try {
      await _functions.httpsCallable('addComment').call({
        'postId': postId,
        'content': content,
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Menggunakan Firestore langsung untuk delete comment
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      final postRef = _db.collection('posts').doc(postId);
      final post = await postRef.get();

      if (!post.exists) throw Exception('Post not found');

      final comments =
          List<Map<String, dynamic>>.from(post.data()?['comments'] ?? []);
      final commentIndex = comments.indexWhere((c) => c['id'] == commentId);

      if (commentIndex == -1) throw Exception('Comment not found');
      if (comments[commentIndex]['userId'] != _auth.currentUser?.uid) {
        throw Exception('Not authorized to delete this comment');
      }

      comments.removeAt(commentIndex);
      await postRef.update({'comments': comments});
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  Future<void> editComment(
      String postId, String commentId, String content) async {
    try {
      await _functions.httpsCallable('editComment').call({
        'postId': postId,
        'commentId': commentId,
        'content': content,
      });
    } catch (e) {
      throw Exception('Failed to edit comment: $e');
    }
  }

  Future<void> editPost(String postId, String content) async {
    try {
      await _functions.httpsCallable('editFilteredPost').call({
        'postId': postId,
        'content': content,
      });
    } catch (e) {
      throw Exception('Failed to edit post: $e');
    }
  }
}
