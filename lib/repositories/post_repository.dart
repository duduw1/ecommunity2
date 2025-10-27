import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommunity/models/post_model.dart'; // Importe o novo modelo de Post

class PostRepository {
  /// Referência à coleção 'posts' no Firestore.
  final CollectionReference _postsCollection =
  FirebaseFirestore.instance.collection('posts');

  /// CREATE: Adiciona um novo post ao Firestore.
  /// Recebe o ID do usuário e o texto do post.
  Future<void> addPost({required String userId, required String text}) async {
    try {
      await _postsCollection.add({
        'userId': userId,
        'text': text,
        // Usar FieldValue.serverTimestamp() é a melhor prática.
        // Garante que a data/hora seja definida pelo servidor do Firebase,
        // evitando problemas com fusos horários ou relógios de dispositivos errados.
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("Post adicionado com sucesso.");
    } catch (e) {
      print("Erro ao adicionar post: $e");
      // Lança o erro novamente para que a UI possa tratá-lo (ex: mostrar um SnackBar)
      throw e;
    }
  }

  /// READ: Busca todos os posts da coleção, ordenados pelos mais recentes.
  /// Ideal para um feed principal.
  Future<List<Post>> getAllPosts() async {
    try {
      final querySnapshot = await _postsCollection
          .orderBy('createdAt', descending: true) // Ordena do mais novo para o mais antigo
          .get();

      // Mapeia cada documento para um objeto Post e retorna uma lista
      return querySnapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      print("Erro ao buscar todos os posts: $e");
      return []; // Retorna uma lista vazia em caso de erro
    }
  }

  /// READ: Busca todos os posts de um usuário específico.
  /// Ideal para a tela de perfil de um usuário.
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

  /// UPDATE: Atualiza o texto de um post existente.
  Future<void> updatePost(String postId, String newText) async {
    try {
      await _postsCollection.doc(postId).update({'text': newText});
      print("Post $postId atualizado com sucesso.");
    } catch (e) {
      print("Erro ao atualizar o post $postId: $e");
      throw e;
    }
  }

  /// DELETE: Remove um post do Firestore.
  Future<void> deletePost(String postId) async {
    try {
      await _postsCollection.doc(postId).delete();
      print("Post $postId deletado com sucesso.");
    } catch (e) {
      print("Erro ao deletar o post $postId: $e");
      throw e;
    }
  }
}