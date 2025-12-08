import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommunity/models/post_model.dart';

class PostRepository {
  final CollectionReference _postsCollection = FirebaseFirestore.instance.collection('posts');

  /// CREATE: Adds a new post.
  /// Requires userName so we can display it in the feed immediately.
  Future<void> addPost({
    required String userId,
    required String userName, // <--- Received from UI
    required String text
  }) async {
    try {
      await _postsCollection.add({
        'userId': userId,
        'userName': userName, // <--- Saved to Firestore
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("Post adicionado com sucesso.");
    } catch (e) {
      print("Erro ao adicionar post: $e");
      throw e;
    }
  }

  /// READ (Stream): Recommended for Social Feeds.
  /// Automatically updates the UI when a new post is added.
  Stream<List<Post>> getPostsStream() {
    return _postsCollection
        .orderBy('createdAt', descending: true)
        .snapshots() // <--- Listen to changes in real-time
        .map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }

  /// READ (Future): Fetches posts once (good for refresh logic).
  Future<List<Post>> getAllPosts() async {
    try {
      final querySnapshot = await _postsCollection
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      print("Erro ao buscar todos os posts: $e");
      return [];
    }
  }

  /// READ: Fetches posts by specific user.
  /// NOTE: This query usually requires a Firestore Composite Index.
  /// Check your debug console for a link to create it if it fails.
  Future<List<Post>> getPostsByUser(String userId) async {
    try {
      final querySnapshot = await _postsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      print("Erro ao buscar posts do usuário $userId: $e");
      return [];
    }
  }

  Future<void> updatePost(String postId, String newText) async {
    await _postsCollection.doc(postId).update({'text': newText});
  }

  Future<void> deletePost(String postId) async {
    await _postsCollection.doc(postId).delete();
  }
}