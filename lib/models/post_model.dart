// Conteúdo correto para: lib/models/post_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;       // O ID do documento do Firestore
  final String userId;   // ID do usuário que criou o post (para vincular ao User)
  final String text;     // O conteúdo do post
  final Timestamp createdAt; // Data e hora da criação (usando Timestamp do Firestore)

  Post({
    required this.id,
    required this.userId,
    required this.text,
    required this.createdAt,
  });

  /// Converte um objeto Post para um Map<String, dynamic> para salvar no Firestore.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'text': text,
      'createdAt': createdAt,
    };
  }

  /// Factory constructor para criar um Post a partir de um DocumentSnapshot do Firestore.
  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      text: data['text'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
