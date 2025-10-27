import 'package:ecommunity/models/post_model.dart';
import 'package:ecommunity/repositories/post_repository.dart'; // Importe seu PostRepository
import 'package:ecommunity/screens/social/widgets/post_card.dart';
import 'package:flutter/material.dart';

import 'create_post_screen.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  // 1. Variáveis de estado
  final PostRepository _postRepository = PostRepository();
  bool _isLoading =
      true; // Começa como 'true' para mostrar o ícone de carregamento
  List<Post> _posts = []; // A lista de posts, começa vazia

  @override
  void initState() {
    super.initState();
    // 2. Chama a função para buscar os posts assim que a tela for construída
    _fetchPosts();
  }

  // 3. Função assíncrona para buscar os dados do repositório
  Future<void> _fetchPosts() async {
    try {
      final fetchedPosts = await _postRepository.getAllPosts();

      // É uma boa prática verificar se o widget ainda está "montado" (na tela)
      // antes de chamar o setState em uma função assíncrona.
      if (mounted) {
        setState(() {
          _posts = fetchedPosts; // Atualiza a lista de posts
          _isLoading = false; // Para de mostrar o ícone de carregamento
        });
      }
    } catch (e) {
      print("Erro ao buscar posts: $e");
      // Mesmo em caso de erro, paramos o carregamento para não ficar infinito
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Opcional: mostrar uma mensagem de erro para o usuário
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível carregar o feed.')),
        );
      }
    }
  }

  void _navigateToCreatePost() async {
    // Navega para a tela de criação
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const CreatePostScreen()));

    // Após a tela de criação ser fechada (com Navigator.pop),
    // o código aqui será executado.
    // Vamos recarregar os posts para mostrar a nova publicação.
    setState(() {
      _isLoading = true; // Mostra o spinner rapidamente enquanto recarrega
    });
    _fetchPosts(); // Chama a função para buscar os posts novamente
  }

  @override
  Widget build(BuildContext context) {
    // Se não estiver carregando E houver posts, mostra a lista
    return Scaffold(
      body: _buildBody(),

      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePost, // Chama a função de navegação
        child: const Icon(Icons.add),
        tooltip: 'Nova Publicação',
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_posts.isEmpty) {
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
    return ListView.builder(
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        return PostCard(post: _posts[index]);
      },
    );
  }
}
