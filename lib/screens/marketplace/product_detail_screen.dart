import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommunity/models/product_model.dart';
import 'package:ecommunity/models/user_model.dart';
import 'package:ecommunity/repositories/chat_repository.dart';
import 'package:ecommunity/repositories/user_repository.dart';
import 'package:ecommunity/screens/social/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final UserRepository _userRepository = UserRepository();
  final ChatRepository _chatRepository = ChatRepository();
  bool _isLoading = false;
  bool _isOwner = false;
  bool _hasInterest = false; // Novo estado para controlar se já tem interesse

  @override
  void initState() {
    super.initState();
    _checkOwnershipAndInterest();
  }

  Future<void> _checkOwnershipAndInterest() async {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Verifica dono
      if (currentUser.uid == widget.product.donatorId) {
        if (mounted) setState(() => _isOwner = true);
      }
      
      // Verifica interesse inicial
      final interested = await _userRepository.hasInterest(currentUser.uid, widget.product.id);
      if (mounted) setState(() => _hasInterest = interested);
    }
  }

  Future<void> _toggleInterest() async {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Chama a nova função de Toggle no repositório
      final isNowInterested = await _userRepository.toggleInterest(currentUser.uid, widget.product);

      if (mounted) {
        setState(() {
          _hasInterest = isNowInterested;
        });

        if (isNowInterested) {
          // Se acabou de marcar interesse, oferece o chat
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Interesse Registrado!'),
              content: const Text(
                  'O produto foi salvo em "Meus Interesses".\n\n'
                  'Deseja enviar uma mensagem para o doador agora?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Depois'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _contactDonator();
                  },
                  child: const Text('Enviar Mensagem'),
                ),
              ],
            ),
          );
        } else {
          // Se removeu o interesse
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Interesse removido.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _contactDonator() async {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() => _isLoading = true);
    
    try {
      final User? myProfile = await _userRepository.getUserById(currentUser.uid);
      final myName = myProfile?.name ?? "Usuário";

      final chatId = await _chatRepository.createOrGetChat(
        currentUser.uid,
        widget.product.donatorId,
        myName,
        widget.product.donatorName,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              otherUserName: widget.product.donatorName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Erro ao abrir chat: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.product.imageUrl.isNotEmpty)
              Image.network(
                widget.product.imageUrl,
                height: 300,
                fit: BoxFit.cover,
              )
            else
              Container(
                height: 300,
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 100, color: Colors.grey),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Chip(
                        label: Text(widget.product.category),
                        backgroundColor: Colors.green[100],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        widget.product.location,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const Spacer(),
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(widget.product.postedAt),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  const Text(
                    "Descrição",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(child: Icon(Icons.person)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Doador: ${widget.product.donatorName}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Text("Comunidade Verdinha"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (!_isOwner)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _toggleInterest,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              // Muda a cor se já tiver interesse
                              backgroundColor: _hasInterest ? Colors.green : Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Icon(_hasInterest ? Icons.check : Icons.favorite),
                            label: Text(
                              _hasInterest ? "INTERESSADO (REMOVER)" : "TENHO INTERESSE",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Só mostra o botão de contato se já tiver interesse (opcional, mas faz sentido)
                         SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _contactDonator,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              icon: const Icon(Icons.chat),
                              label: const Text("Entrar em Contato"),
                            ),
                          ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Este é seu produto.",
                        style: TextStyle(
                            color: Colors.amber, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
