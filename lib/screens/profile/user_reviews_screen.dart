import 'package:ecommunity/models/product_model.dart';
import 'package:ecommunity/models/user_model.dart';
import 'package:ecommunity/repositories/product_repository.dart';
import 'package:ecommunity/repositories/user_repository.dart';
import 'package:ecommunity/screens/profile/public_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
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
  List<Product> _reviewsReceived = [];
  List<Product> _reviewsMade = [];
  Map<String, User> _usersMap = {};
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = auth.FirebaseAuth.instance.currentUser?.uid;
    _loadAllReviews();
  }

  Future<void> _loadAllReviews() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _productRepo.getDonationReviews(widget.userId),
        _productRepo.getReviewsMadeByUser(widget.userId),
      ]);

      final received = results[0];
      final made = results[1];
      final Set<String> userIdsToFetch = {};
      userIdsToFetch.addAll(received.map((p) => p.receiverId).whereType<String>());
      userIdsToFetch.addAll(made.map((p) => p.donatorId));

      final users = await _userRepo.getUsersByIds(userIdsToFetch.toList());
      final Map<String, User> usersMap = { for (var user in users) user.id: user };

      if (mounted) {
        setState(() {
          _reviewsReceived = received;
          _reviewsMade = made;
          _usersMap = usersMap;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar avaliações: $e')));
      }
    } finally {
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

  void _showEditReviewDialog(Product review) {
    int rating = review.receiverRating ?? 5;
    final commentController = TextEditingController(text: review.receiverComment);
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Editar Avaliação'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Altere sua nota ou comentário:'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber, size: 32,
                          ),
                          onPressed: isSaving ? null : () => setStateDialog(() => rating = index + 1),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      enabled: !isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Comentário',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context), 
                  child: const Text('Cancelar')
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(80, 36)),
                  onPressed: isSaving ? null : () async {
                    setStateDialog(() => isSaving = true);
                    try {
                      // A chamada ao servidor continua igual
                      await _productRepo.updateReview(
                        productId: review.id,
                        oldRating: review.receiverRating ?? 0,
                        newRating: rating,
                        newComment: commentController.text,
                      );
                      
                      if (mounted) {
                        // ATUALIZAÇÃO INSTANTÂNEA DA UI
                        final index = _reviewsMade.indexWhere((p) => p.id == review.id);
                        if (index != -1) {
                          final updatedReview = _reviewsMade[index].copyWith(
                            receiverRating: rating,
                            receiverComment: commentController.text,
                          );
                          setState(() {
                            _reviewsMade[index] = updatedReview;
                          });
                        }

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avaliação atualizada!')));
                      }

                    } catch (e) {
                       if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
                      }
                    } finally {
                      if(mounted) setStateDialog(() => isSaving = false);
                    }
                  },
                  child: isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Salvar'),
                ),
              ],
            );
          }
        );
      },
    );
  }

   @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Avaliações de ${widget.userName}"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Recebidas"),
              Tab(text: "Feitas"),
            ],
          ),
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              children: [
                _buildReviewList(_reviewsReceived, isReceived: true),
                _buildReviewList(_reviewsMade, isReceived: false),
              ],
            ),
      ),
    );
  }

  Widget _buildReviewList(List<Product> reviews, {required bool isReceived}) {
    if (reviews.isEmpty) {
      return Center(
        child: Text(isReceived ? "Nenhuma avaliação recebida." : "Nenhuma avaliação feita."),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        final relatedUserId = isReceived ? review.receiverId : review.donatorId;
        final relatedUser = _usersMap[relatedUserId];
        final rating = review.receiverRating ?? 0;
        final comment = review.receiverComment ?? "";
        final date = review.donatedAt?.toDate() ?? DateTime.now();
        final canEdit = !isReceived && widget.userId == _currentUserId;

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
                        if (relatedUser != null) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: relatedUser.id)));
                        }
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blueAccent.withOpacity(0.2),
                        child: Text(
                          relatedUser?.name.isNotEmpty == true ? relatedUser!.name[0].toUpperCase() : "?",
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
                            relatedUser?.name ?? "Usuário Desconhecido", 
                            style: const TextStyle(fontWeight: FontWeight.bold)
                          ),
                          Text(
                            _timeAgo(date), 
                            style: TextStyle(fontSize: 12, color: Colors.grey[600])
                          ),
                        ],
                      ),
                    ),
                    if (canEdit)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                        onPressed: () => _showEditReviewDialog(review),
                        tooltip: "Editar Avaliação",
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (i) => Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 18,
                  )),
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
                      Icon(
                        isReceived ? Icons.volunteer_activism : Icons.inventory_2_outlined, 
                        size: 16, 
                        color: Colors.grey
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isReceived 
                            ? "Item doado: ${review.title}" 
                            : "Item recebido: ${review.title}",
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
    );
  }
}
