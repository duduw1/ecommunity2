import 'package:ecommunity/models/chat_model.dart';
import 'package:ecommunity/repositories/chat_repository.dart';
import 'package:ecommunity/screens/profile/public_profile_screen.dart'; // Import
import 'package:ecommunity/screens/social/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return const Center(child: Text("Faça login para ver suas mensagens."));

    final ChatRepository chatRepository = ChatRepository();

    return Scaffold(
      appBar: AppBar(title: const Text("Minhas Conversas")),
      body: StreamBuilder<List<Chat>>(
        stream: chatRepository.getUserChats(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Nenhuma conversa iniciada."));
          }

          final chats = snapshot.data!;
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUserId = chat.participants.firstWhere((id) => id != currentUserId, orElse: () => 'Desconhecido');
              final otherUserName = chat.participantNames[otherUserId] ?? "Usuário";

              return Dismissible(
                key: Key(chat.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Confirmar Exclusão"),
                        content: const Text("Tem certeza de que deseja excluir esta conversa e todas as mensagens?"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("Cancelar"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) async {
                  try {
                    await chatRepository.deleteChat(chat.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Conversa excluída.')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao excluir: $e')),
                    );
                  }
                },
                child: ListTile(
                  leading: InkWell( // Clicar no avatar abre perfil
                    onTap: () {
                       Navigator.push(context, MaterialPageRoute(builder: (c) => PublicProfileScreen(userId: otherUserId)));
                    },
                    child: const CircleAvatar(child: Icon(Icons.person)),
                  ),
                  title: Text(otherUserName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    chat.lastMessage.isNotEmpty ? chat.lastMessage : "Inicie a conversa...",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatId: chat.id,
                          otherUserName: otherUserName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
