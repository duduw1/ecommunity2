import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommunity/models/user_model.dart';
import 'package:ecommunity/screens/auth/login_screen.dart';
import 'package:ecommunity/screens/profile/edit_profile_screen.dart';
import 'package:ecommunity/screens/profile/my_activity_screen.dart';
import 'package:ecommunity/screens/profile/user_list_screen.dart';
import 'package:ecommunity/screens/profile/user_reviews_screen.dart'; // Import da tela de reviews
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final firebase_auth.User? authUser = firebase_auth.FirebaseAuth.instance.currentUser;

      if (authUser == null) {
        setState(() {
          _currentUser = null;
          _isLoading = false;
        });
        return;
      }

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _currentUser = User.fromFirestore(doc);
          _isLoading = false;
        });
      } else {
        setState(() {
          _currentUser = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await firebase_auth.FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao sair: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _currentUser == null
            ? _buildErrorView()
            : _buildProfileView(textColor, isDarkMode),
      ),
    );
  }

  Widget _buildProfileView(Color textColor, bool isDarkMode) {
    final isBusiness = _currentUser!.accountType == 'business';

    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar e Tipo de Conta
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.green,
                  child: Text(
                    _currentUser!.name.isNotEmpty ? _currentUser!.name[0].toUpperCase() : '?',
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
            
            // Nome e Email
            Text(
              _currentUser!.name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              _currentUser!.email,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

            // Rating / Reputação (Clicável)
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserReviewsScreen(
                      userId: _currentUser!.id, 
                      userName: _currentUser!.name
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      "${_currentUser!.rating.toStringAsFixed(1)} (${_currentUser!.ratingCount} avaliações)",
                      style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // Stats Row (Pontos, Seguidores, Seguindo)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem("Pontos", _currentUser!.points.toString(), Colors.green),
                
                // Botão Seguidores
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserListScreen(
                          title: "Seguidores",
                          userIds: _currentUser!.followers,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildStatItem("Seguidores", _currentUser!.followers.length.toString(), textColor),
                  ),
                ),

                // Botão Seguindo
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserListScreen(
                          title: "Seguindo",
                          userIds: _currentUser!.following,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildStatItem("Seguindo", _currentUser!.following.length.toString(), textColor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // Menus
            _buildActionButton(
              icon: Icons.history,
              text: 'Minhas Atividades',
              textColor: textColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyActivityScreen()),
                );
              },
            ),
            if (isBusiness) // Exemplo: Menu extra para empresas
               _buildActionButton(
                icon: Icons.storefront,
                text: 'Gerenciar Loja',
                textColor: textColor,
                onTap: () {
                  // Navegar para gerenciamento da loja
                },
              ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.edit_outlined,
              text: 'Editar Perfil',
              textColor: textColor,
              onTap: () async {
                final bool? result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(user: _currentUser!),
                  ),
                );
                if (result == true) {
                  _loadUserData();
                }
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.logout,
              text: 'Sair (Logout)',
              textColor: Colors.red,
              color: Colors.red,
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color? color,
    Color? textColor,
  }) {
    final iconColor = color ?? textColor ?? Colors.black87;
    final finalTextColor = textColor ?? Colors.black87;

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(text, style: TextStyle(color: finalTextColor, fontWeight: FontWeight.w500)),
      onTap: onTap,
      trailing: Icon(Icons.chevron_right, color: iconColor.withOpacity(0.5)),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            const Text(
              'Não foi possível carregar os dados do usuário.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _logout,
              child: const Text('Voltar para o Login'),
            )
          ],
        ),
      ),
    );
  }
}
