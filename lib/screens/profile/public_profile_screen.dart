import 'package:ecommunity/models/user_model.dart';
import 'package:ecommunity/repositories/user_repository.dart';
import 'package:ecommunity/screens/profile/user_reviews_screen.dart'; // Import da tela de reviews
import 'package:firebase_auth/firebase_auth.dart' as auth; // Alias para evitar conflito
import 'package:flutter/material.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final UserRepository _userRepository = UserRepository();
  final String _currentUserId = auth.FirebaseAuth.instance.currentUser?.uid ?? '';
  
  User? _user; // Refere-se a ecommunity/models/user_model.dart
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isMe = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      if (widget.userId == _currentUserId) {
        setState(() => _isMe = true);
      }

      final user = await _userRepository.getUserById(widget.userId);
      
      bool isFollowing = false;
      if (user != null && _currentUserId.isNotEmpty) {
        isFollowing = user.followers.contains(_currentUserId);
      }

      if (mounted) {
        setState(() {
          _user = user;
          _isFollowing = isFollowing;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar perfil público: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_currentUserId.isEmpty || _user == null) return;

    // Optimistic Update
    setState(() {
      _isFollowing = !_isFollowing;
      if (_isFollowing) {
        _user!.followers.add(_currentUserId);
      } else {
        _user!.followers.remove(_currentUserId);
      }
    });

    try {
      await _userRepository.toggleFollow(_currentUserId, _user!.id);
    } catch (e) {
      // Revert if error
      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
           if (_isFollowing) {
            _user!.followers.add(_currentUserId);
          } else {
            _user!.followers.remove(_currentUserId);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao atualizar.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Perfil")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text("Usuário não encontrado."))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final isBusiness = _user!.accountType == 'business';
    final followersCount = _user!.followers.length;
    final followingCount = _user!.following.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blueAccent,
                child: Text(
                  _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 40, color: Colors.white),
                ),
              ),
              if (isBusiness)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.store, color: Colors.white, size: 20),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _user!.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          
          // Rating / Reputação (Clicável)
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (_) => UserReviewsScreen(userId: _user!.id, userName: _user!.name)
                )
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    "${_user!.rating.toStringAsFixed(1)} (${_user!.ratingCount} avaliações)",
                    style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
                ],
              ),
            ),
          ),

          if (isBusiness) ...[
            const SizedBox(height: 8),
            const Chip(label: Text("Conta Empresarial"), backgroundColor: Colors.blue, labelStyle: TextStyle(color: Colors.white)),
          ],
          
          const SizedBox(height: 24),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem("Pontos", _user!.points.toString(), Colors.green),
              _buildStatItem("Seguidores", followersCount.toString(), null),
              _buildStatItem("Seguindo", followingCount.toString(), null),
            ],
          ),

          const SizedBox(height: 32),

          // Action Button
          if (!_isMe)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _toggleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFollowing ? Colors.grey[300] : Colors.blue,
                  foregroundColor: _isFollowing ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(_isFollowing ? "Deixar de Seguir" : "Seguir"),
              ),
            )
          else
            const Text("Este é seu perfil público.", style: TextStyle(color: Colors.grey)),

          const SizedBox(height: 20),
          const Divider(),
          // Futuro: Lista de posts do usuário aqui
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Atividades recentes (Em breve)", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color? color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
