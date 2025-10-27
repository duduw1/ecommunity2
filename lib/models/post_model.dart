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
  /// O 'id' não é incluído aqui porque ele é o nome do documento, não um campo.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'text': text,
      'createdAt': createdAt,
    };
  }

  /// Factory constructor para criar um Post a partir de um DocumentSnapshot do Firestore.
  factory Post.fromFirestore(DocumentSnapshot doc) {
    // Pega os dados do documento, garantindo que é um Map
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Post(
      id: doc.id, // O ID vem do próprio DocumentSnapshot
      userId: data['userId'] ?? '', // Usa um valor padrão caso o campo não exista
      text: data['text'] ?? '',
      // Se 'createdAt' não existir, usa a data atual como fallback
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}