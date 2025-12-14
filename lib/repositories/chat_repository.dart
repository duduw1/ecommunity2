import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommunity/models/chat_model.dart';

class ChatRepository {
  final CollectionReference _chatsCollection =
      FirebaseFirestore.instance.collection('chats');

  /// Cria um chat entre dois usuários se não existir, ou retorna o ID do existente.
  Future<String> createOrGetChat(
      String currentUserId, String otherUserId, String currentUserName, String otherUserName) async {
    try {
      // Verifica se já existe chat entre os dois
      final querySnapshot = await _chatsCollection
          .where('participants', arrayContains: currentUserId)
          .get();

      // Filtra localmente para encontrar o chat exato com o outro usuário
      // (Firestore não suporta queries "array contains both X and Y" diretamente de forma simples)
      for (var doc in querySnapshot.docs) {
        final participants = List<String>.from(doc['participants']);
        if (participants.contains(otherUserId)) {
          return doc.id;
        }
      }

      // Se não encontrou, cria um novo
      final newChatDoc = await _chatsCollection.add({
        'participants': [currentUserId, otherUserId],
        'participantNames': {
          currentUserId: currentUserName,
          otherUserId: otherUserName,
        },
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      return newChatDoc.id;
    } catch (e) {
      print("Erro ao criar/buscar chat: $e");
      throw Exception('Falha ao iniciar conversa.');
    }
  }

  /// Busca todos os chats do usuário
  Stream<List<Chat>> getUserChats(String userId) {
    return _chatsCollection
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Chat.fromFirestore(doc)).toList();
    });
  }

  /// Envia mensagem
  Future<void> sendMessage(String chatId, String senderId, String text) async {
    final timestamp = FieldValue.serverTimestamp();

    // 1. Adiciona mensagem na subcoleção
    await _chatsCollection.doc(chatId).collection('messages').add({
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
    });

    // 2. Atualiza o documento pai do chat com a última mensagem
    await _chatsCollection.doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': timestamp,
    });
  }

  /// Ouve as mensagens de um chat específico em tempo real
  Stream<List<ChatMessage>> getMessages(String chatId) {
    return _chatsCollection
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
    });
  }
}
