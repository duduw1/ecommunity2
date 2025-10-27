import 'package:ecommunity/repositories/post_repository.dart';
import 'package:ecommunity/providers/auth_provider.dart';
import 'package:flutter/material.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  // Chave para identificar e validar nosso formulário
  final _formKey = GlobalKey<FormState>();

  // Controlador para acessar o texto do campo de entrada
  final _postTextController = TextEditingController();

  // Estado para controlar o processo de publicação
  bool _isPosting = false;

  @override
  void dispose() {
    // É importante limpar o controlador quando o widget for removido da árvore
    _postTextController.dispose();
    super.dispose();
  }

  /// Lida com a lógica de submissão do post
  Future<void> _submitPost() async {
    // 1. Valida o formulário. Se não for válido, não faz nada.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Pega o ID do usuário logado. Se não houver, mostra erro.
    final userId = SessionManager().getCurrentUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Usuário não autenticado.')),
      );
      return;
    }

    // 3. Inicia o estado de "publicando"
    setState(() {
      _isPosting = true;
    });

    try {
      // 4. Chama o repositório para adicionar o post
      await PostRepository().addPost(
        userId: userId,
        text: _postTextController.text.trim(), // trim() remove espaços em branco
      );

      // 5. Em caso de sucesso, mostra mensagem e fecha a tela
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publicação criada com sucesso!')),
        );
        Navigator.of(context).pop(); // Volta para a tela anterior (o feed)
      }
    } catch (e) {
      // 6. Em caso de erro, mostra uma mensagem de falha
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao criar a publicação. Tente novamente.')),
        );
      }
    } finally {
      // 7. Independentemente de sucesso ou falha, finaliza o estado de "publicando"
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Publicação'),
        actions: [
          // Botão de Publicar na AppBar
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              // Desabilita o botão enquanto estiver publicando
              onPressed: _isPosting ? null : _submitPost,
              child: _isPosting
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text('PUBLICAR'),
              style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white.withOpacity(0.5)
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Campo de texto para o conteúdo do post
              TextFormField(
                controller: _postTextController,
                autofocus: true, // Abre o teclado automaticamente
                decoration: const InputDecoration(
                    hintText: 'No que você está pensando?',
                    border: InputBorder.none, // Um visual mais limpo, sem bordas
                    hintStyle: TextStyle(color: Colors.grey)
                ),
                maxLines: null, // Permite que o campo cresça verticalmente
                keyboardType: TextInputType.multiline,
                validator: (value) {
                  // Validador para garantir que o post não seja vazio
                  if (value == null || value.trim().isEmpty) {
                    return 'A publicação não pode estar vazia.';
                  }
                  if (value.length > 280) { // Exemplo de limite de caracteres
                    return 'A publicação não pode ter mais de 280 caracteres.';
                  }
                  return null; // Retornar null significa que a validação passou
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}