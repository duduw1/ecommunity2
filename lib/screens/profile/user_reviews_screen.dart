import 'package:ecommunity/models/product_model.dart';
import 'package:ecommunity/models/user_model.dart';
import 'package:ecommunity/repositories/product_repository.dart';
import 'package:ecommunity/repositories/user_repository.dart';
import 'package:ecommunity/screens/profile/public_profile_screen.dart';
import 'package:flutter/material.dart';

class UserReviewsScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const UserReviewsScreen({super.key, required this.userId, required this.userName});

  @override
  State<UserReviewsScreen> createState() => _UserReviewsScreenState();
}

class _UserReviewsScreenState extends State<UserReviewsScreen> {
  final ProductRepository _productRepo = ProductRepository();
  final UserRepository _userRepo = UserRepository();
  
  bool _isLoading = true;
  List<Product> _reviews = [];
  Map<String, User> _receiversMap = {};

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final products = await _productRepo.getDonationReviews(widget.userId);
      
      // Buscar dados dos usuários que avaliaram (recebedores)
      // Filtra IDs nulos e duplicados
      final receiverIds = products
          .map((p) => p.receiverId)
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      final receivers = await _userRepo.getUsersByIds(receiverIds);
      
      final Map<String, User> receiversMap = {
        for (var user in receivers) user.id: user
      };

      if (mounted) {
        setState(() {
          _reviews = products;
          _receiversMap = receiversMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return "há ${(diff.inDays / 365).floor()} anos";
    if (diff.inDays > 30) return "há ${(diff.inDays / 30).floor()} meses";
    if (diff.inDays > 1) return "há ${diff.inDays} dias";
    if (diff.inDays == 1) return "há 1 dia";
    if (diff.inHours > 0) return "há ${diff.inHours} horas";
    if (diff.inMinutes > 0) return "há ${diff.inMinutes} minutos";
    return "agora mesmo";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Avaliações de ${widget.userName}")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _reviews.isEmpty
          ? const Center(child: Text("Nenhuma avaliação recebida ainda."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _reviews.length,
              itemBuilder: (context, index) {
                final review = _reviews[index];
                final receiver = _receiversMap[review.receiverId];
                final rating = review.receiverRating ?? 0;
                final comment = review.receiverComment ?? "";
                final date = review.donatedAt?.toDate() ?? DateTime.now();

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (receiver != null) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: receiver.id)));
                                }
                              },
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.blueAccent.withOpacity(0.2),
                                child: Text(
                                  receiver?.name.isNotEmpty == true ? receiver!.name[0].toUpperCase() : "?",
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    receiver?.name ?? "Usuário Desconhecido", 
                                    style: const TextStyle(fontWeight: FontWeight.bold)
                                  ),
                                  Text(
                                    _timeAgo(date), 
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600])
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: List.generate(5, (i) => Icon(
                                i < rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 18,
                              )),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          comment.isEmpty ? "Sem comentário." : comment,
                          style: TextStyle(fontStyle: comment.isEmpty ? FontStyle.italic : FontStyle.normal),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.volunteer_activism, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Item doado: ${review.title}", 
                                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)
                                )
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
