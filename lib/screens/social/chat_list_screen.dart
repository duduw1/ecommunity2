import 'package:ecommunity/models/chat_model.dart';
import 'package:ecommunity/repositories/chat_repository.dart';
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
              
              // Descobre quem é o "outro" participante
              final otherUserId = chat.participants.firstWhere((id) => id != currentUserId);
              final otherUserName = chat.participantNames[otherUserId] ?? "Usuário";

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
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
              );
            },
          );
        },
      ),
    );
  }
}
