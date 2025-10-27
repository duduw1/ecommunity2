import 'package:ecommunity/models/post_model.dart';
import 'package:ecommunity/models/user_model.dart';      // Importe o User Model
import 'package:ecommunity/repositories/user_repository.dart'; // Importe o User Repository
import 'package:flutter/material.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  // Variáveis de estado para armazenar os dados do usuário e o estado de carregamento
  User? _author;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    // Assim que o widget for criado, busca os dados do autor
    _fetchAuthorData();
  }

  Future<void> _fetchAuthorData() async {
    // Usando o userId do post recebido via 'widget.post'
    final user = await UserRepository().getUserById(widget.post.userId);
    if (mounted) {
      setState(() {
        _author = user;
        _isLoadingUser = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      // ... estilos do card ...
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Enquanto carrega, mostra um avatar genérico. Depois, o do usuário.
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  child: _isLoadingUser
                      ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                    _author?.name.isNotEmpty ?? false ? _author!.name[0].toUpperCase() : '?',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mostra um placeholder enquanto carrega o nome
                      if (_isLoadingUser)
                        Container(
                          height: 16,
                          width: 120,
                          color: Colors.grey.shade200,
                        )
                      else
                        Text(
                          _author?.name ?? 'Usuário desconhecido', // Nome do autor ou um fallback
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      // A data do post já está disponível

                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Text(
              widget.post.text,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
