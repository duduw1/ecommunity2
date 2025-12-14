import 'package:ecommunity/models/post_model.dart';
import 'package:ecommunity/repositories/post_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final PostRepository _postRepository = PostRepository();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final String _currentUserName = FirebaseAuth.instance.currentUser?.displayName ?? 'Usuário';

  // Variáveis para atualização otimista
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.likes.contains(_currentUserId);
    _likeCount = widget.post.likes.length;
  }

  // Atualiza o estado se o widget pai mandar um novo post (ex: via Stream)
  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.likes != widget.post.likes) {
      _isLiked = widget.post.likes.contains(_currentUserId);
      _likeCount = widget.post.likes.length;
    }
  }

  void _handleLike() async {
    if (_currentUserId.isEmpty) return;

    // Optimistic Update: Atualiza UI imediatamente
    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _likeCount--;
      } else {
        _isLiked = true;
        _likeCount++;
      }
    });
    
    // Chama o backend em segundo plano
    try {
      await _postRepository.toggleLike(widget.post.id, _currentUserId, _currentUserName);
    } catch (e) {
      // Reverte se der erro
      if (mounted) {
        setState(() {
          if (_isLiked) {
            _isLiked = false;
            _likeCount--;
          } else {
            _isLiked = true;
            _likeCount++;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao curtir")));
      }
    }
  }

  void _showCommentsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CommentsSheet(postId: widget.post.id),
    );
  }

  String _formatDateTime(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    // Usamos as variáveis locais (_isLiked, _likeCount) ao invés das do widget.post diretamente
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green[100],
                  child: Text(
                    widget.post.userName.isNotEmpty ? widget.post.userName[0].toUpperCase() : '?',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800]),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        _formatDateTime(widget.post.createdAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12.0),
            
            // Texto
            Text(
              widget.post.text,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),

            // Imagem
            if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.post.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox.shrink(); 
                    },
                  ),
                ),
              ),

            const SizedBox(height: 12.0),
            const Divider(),

            // Botões de Ação
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Botão de Like
                InkWell(
                  onTap: _handleLike,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_likeCount',
                          style: TextStyle(
                            color: _isLiked ? Colors.red : Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Botão de Comentário
                InkWell(
                  onTap: () => _showCommentsModal(context),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.mode_comment_outlined, color: Colors.grey, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.post.commentCount}', // Este atualiza via Stream do widget pai
                          style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final String postId;
  const _CommentsSheet({required this.postId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final PostRepository _postRepository = PostRepository();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isSending = false;

  void _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      String userName = 'Usuário'; 
      await _postRepository.addComment(
        widget.postId,
        _currentUserId,
        userName,
        _commentController.text.trim(),
      );
      _commentController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      // Tratar erro
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatDateTime(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Comentários", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: _postRepository.getComments(widget.postId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final comments = snapshot.data!;

                if (comments.isEmpty) {
                  return const Center(child: Text("Seja o primeiro a comentar!", style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        child: Text(comment.userName[0].toUpperCase()),
                      ),
                      title: Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(comment.text),
                      trailing: Text(
                        _formatDateTime(comment.createdAt),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Escreva um comentário...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSending 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Icon(Icons.send, color: Colors.blue),
                  onPressed: _isSending ? null : _sendComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
