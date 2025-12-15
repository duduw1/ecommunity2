import 'package:ecommunity/models/post_model.dart';
import 'package:ecommunity/repositories/post_repository.dart';
import 'package:ecommunity/screens/social/widgets/post_card.dart';
import 'package:flutter/material.dart';

import 'create_post_screen.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final PostRepository _postRepository = PostRepository();

  void _navigateToCreatePost() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CreatePostScreen()),
    );
    // Não precisamos mais recarregar manualmente, o StreamBuilder fará isso!
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Post>>(
        stream: _postRepository.getPostsStream(), // Ouve as mudanças em tempo real
        builder: (context, snapshot) {
          // 1. Verificando estado de conexão e erros
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar posts: ${snapshot.error}'),
            );
          }

          // 2. Verificando se há dados
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Ainda não há publicações.\nSeja o primeiro a compartilhar algo!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          }

          // 3. Construindo a lista com os dados atualizados
          final posts = snapshot.data!;
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return PostCard(post: posts[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePost,
        child: const Icon(Icons.add),
        tooltip: 'Nova Publicação',
      ),
    );
  }
}
