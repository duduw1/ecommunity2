import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommunity/models/post_model.dart';
import 'package:ecommunity/repositories/notification_repository.dart';

class PostRepository {
  final CollectionReference _postsCollection = FirebaseFirestore.instance.collection('posts');
  final NotificationRepository _notificationRepository = NotificationRepository();

  /// CREATE: Adds a new post with optional image.
  Future<void> addPost({
    required String userId,
    required String userName,
    required String text,
    String? imageUrl,
  }) async {
    try {
      await _postsCollection.add({
        'userId': userId,
        'userName': userName,
        'text': text,
        'imageUrl': imageUrl,
        'likes': [], // Inicializa lista vazia
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Erro ao adicionar post: $e");
      throw e;
    }
  }

  /// READ (Stream): Social Feed
  Stream<List<Post>> getPostsStream() {
    return _postsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }

  /// READ (Future): Refresh logic
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

  /// LIKE TOGGLE: Curte ou descurte um post
  Future<void> toggleLike(String postId, String userId, String userName) async {
    final docRef = _postsCollection.doc(postId);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) return;

    final post = Post.fromFirestore(docSnapshot);
    final isLiked = post.likes.contains(userId);

    if (isLiked) {
      // Remove like
      await docRef.update({
        'likes': FieldValue.arrayRemove([userId])
      });
    } else {
      // Adiciona like
      await docRef.update({
        'likes': FieldValue.arrayUnion([userId])
      });

      // Envia notificação para o dono do post (se não for ele mesmo)
      if (post.userId != userId) {
        _notificationRepository.sendNotification(
          toUserId: post.userId,
          fromUserName: userName,
          type: 'like',
          message: 'curtiu sua publicação.',
          relatedId: postId,
        );
      }
    }
  }

  /// ADD COMMENT: Adiciona comentário e notifica
  Future<void> addComment(String postId, String userId, String userName, String text) async {
    final postRef = _postsCollection.doc(postId);
    
    // 1. Adiciona na subcoleção de comentários
    await postRef.collection('comments').add({
      'userId': userId,
      'userName': userName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Incrementa contador no post principal
    await postRef.update({
      'commentCount': FieldValue.increment(1),
    });

    // 3. Notifica o dono do post
    final postSnapshot = await postRef.get();
    final post = Post.fromFirestore(postSnapshot);

    if (post.userId != userId) {
      _notificationRepository.sendNotification(
        toUserId: post.userId,
        fromUserName: userName,
        type: 'comment',
        message: 'comentou na sua publicação: "$text"',
        relatedId: postId,
      );
    }
  }

  /// GET COMMENTS
  Stream<List<Comment>> getComments(String postId) {
    return _postsCollection
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false) // Mais antigos primeiro
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
    });
  }

  /// GET LIKED POSTS: Busca posts que o usuário curtiu
  Future<List<Post>> getLikedPosts(String userId) async {
    try {
      final querySnapshot = await _postsCollection
          .where('likes', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      print("Erro ao buscar posts curtidos: $e");
      return [];
    }
  }
}
