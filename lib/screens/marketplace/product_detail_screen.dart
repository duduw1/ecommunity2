import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommunity/models/product_model.dart';
import 'package:ecommunity/models/user_model.dart';
import 'package:ecommunity/repositories/chat_repository.dart';
import 'package:ecommunity/repositories/product_repository.dart';
import 'package:ecommunity/repositories/user_repository.dart';
import 'package:ecommunity/screens/profile/public_profile_screen.dart';
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
  final ProductRepository _productRepository = ProductRepository();

  bool _isLoading = false;
  bool _isOwner = false;
  bool _hasInterest = false;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.product.status;
    _checkOwnershipAndInterest();
  }

  Future<void> _checkOwnershipAndInterest() async {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      if (currentUser.uid == widget.product.donatorId) {
        if (mounted) setState(() => _isOwner = true);
      }
      
      final interested = await _userRepository.hasInterest(currentUser.uid, widget.product.id);
      if (mounted) setState(() => _hasInterest = interested);
    }
  }

  // Novo método para selecionar recebedor e avaliar
  void _showSelectReceiverDialog() {
    final emailController = TextEditingController();
    int selectedRating = 5;

    // Guardar o ScaffoldMessenger do contexto PAI para usar depois que o dialog fechar
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Confirmar Doação'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Você ganhará 50 pontos por esta ação ecológica! 🌱", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text('Quem recebeu a doação?'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-mail do recebedor',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    const Text("Avalie o recebedor:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < selectedRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                          onPressed: () {
                            setStateDialog(() {
                              selectedRating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    Center(child: Text("$selectedRating/5 estrelas", style: TextStyle(color: Colors.grey[600]))),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    // Normaliza para lowercase
                    final email = emailController.text.trim().toLowerCase();
                    if (email.isEmpty) {
                      messenger.showSnackBar(const SnackBar(content: Text('Digite um email.')));
                      return;
                    }
                    Navigator.pop(dialogContext); // Fecha Dialog usando dialogContext

                    // Feedback visual
                    messenger.showSnackBar(const SnackBar(content: Text('Processando doação...')));

                    setState(() => _isLoading = true);
                    
                    try {
                      // Busca usando email normalizado
                      final user = await _userRepository.getUserByEmail(email);
                      
                      if (user == null) {
                        throw Exception('Usuário não encontrado com este e-mail. Verifique a grafia.');
                      }

                      if (user.id == widget.product.donatorId) {
                         throw Exception('Você não pode doar para si mesmo!');
                      }

                      await _productRepository.markAsDonated(
                        productId: widget.product.id, 
                        receiverId: user.id, 
                        donatorId: widget.product.donatorId,
                        donatorName: widget.product.donatorName,
                        ratingToReceiver: selectedRating,
                      );

                      if (mounted) {
                        setState(() {
                          _currentStatus = 'Donated';
                          _isLoading = false;
                        });
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Doação registrada! Avaliação enviada e +50 pontos ganhos! 🎉'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() => _isLoading = false);
                        messenger.showSnackBar(SnackBar(content: Text('Erro: $e')));
                      }
                    }
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _toggleInterest() async {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Você precisa estar logado.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final isNowInterested = await _userRepository.toggleInterest(currentUser.uid, widget.product);
      if (mounted) {
        setState(() => _hasInterest = isNowInterested);
        if (isNowInterested) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Interesse Registrado!'),
              content: const Text('O produto foi salvo em "Meus Interesses".\n\nDeseja enviar uma mensagem para o doador agora?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Depois')),
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Interesse removido.')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
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
      final chatId = await _chatRepository.createOrGetChat(currentUser.uid, widget.product.donatorId, myName, widget.product.donatorName);
      final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
      final lastMessage = chatDoc.data()?['lastMessage'] as String? ?? '';
      final interestMessage = "Olá! Tenho interesse na doação: ${widget.product.title}.";
      if (lastMessage != interestMessage) await _chatRepository.sendMessage(chatId, currentUser.uid, interestMessage);
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(chatId: chatId, otherUserName: widget.product.donatorName)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao abrir chat: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openDonatorProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => PublicProfileScreen(userId: widget.product.donatorId)));
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final isDonated = _currentStatus == 'Donated';
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(widget.product.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                if (widget.product.imageUrl.isNotEmpty)
                  Image.network(widget.product.imageUrl, height: 300, width: double.infinity, fit: BoxFit.cover)
                else
                  Container(height: 300, color: isDarkMode ? Colors.grey[800] : Colors.grey[300], child: const Icon(Icons.image, size: 100, color: Colors.grey)),
                
                if (isDonated)
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      color: Colors.red.withOpacity(0.8),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: const Text(
                        "DOADO",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
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
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Chip(
                        label: Text(widget.product.category, style: TextStyle(color: isDarkMode ? Colors.green[200] : Colors.green[900])),
                        backgroundColor: isDarkMode ? Colors.green[900]!.withOpacity(0.5) : Colors.green[100],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(widget.product.location, style: const TextStyle(color: Colors.grey)),
                      const Spacer(),
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(_formatDate(widget.product.postedAt), style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const Divider(height: 32),

                  const Text("Descrição", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.product.description, style: const TextStyle(fontSize: 16, height: 1.5)),
                  const SizedBox(height: 24),

                  InkWell(
                    onTap: _openDonatorProfile,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest, // Cor adaptativa do tema
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(child: Icon(Icons.person)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Doador: ${widget.product.donatorName}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Text("Comunidade Verdinha"),
                              Text("Ver Perfil", style: TextStyle(color: theme.colorScheme.primary, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Lógica de Botões
                  if (_isOwner) ...[
                    if (!isDonated)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _showSelectReceiverDialog, // Chama o novo dialog
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text("MARCAR COMO DOADO (+50 pts)"),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.green[900]!.withOpacity(0.3) : Colors.green[50], 
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green)
                        ),
                        child: const Text("Você já doou este item. Parabéns! ♻️", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ),
                  ] else ...[
                    if (!isDonated) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _toggleInterest,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: _hasInterest ? Colors.green : theme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          icon: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Icon(_hasInterest ? Icons.check : Icons.favorite),
                          label: Text(_hasInterest ? "INTERESSADO (REMOVER)" : "TENHO INTERESSE", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _contactDonator,
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          icon: const Icon(Icons.chat),
                          label: const Text("Entrar em Contato"),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.red[900]!.withOpacity(0.3) : Colors.red[50],
                          borderRadius: BorderRadius.circular(8), 
                          border: Border.all(color: Colors.red[200]!)
                        ),
                        child: const Text("Este item já foi doado.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
