import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:ecommunity/screens/profile/edit_profile_screen.dart';
import 'package:ecommunity/screens/profile/my_activity_screen.dart'; // Importe a tela
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // Alias Firebase Auth
import 'package:flutter/material.dart';
import 'package:ecommunity/models/user_model.dart'; // Your local User model
import 'package:ecommunity/screens/auth/login_screen.dart'; // Import your LoginScreen

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
      print("Error loading profile: $e");
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
    // Definir cores baseadas no tema
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final appBarColor = isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: appBarColor,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
          ? _buildErrorView()
          : _buildProfileView(textColor),
    );
  }

  Widget _buildProfileView(Color textColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.green,
            child: Text(
              _currentUser!.name.isNotEmpty ? _currentUser!.name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 40, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentUser!.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _currentUser!.email,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // --- Action Buttons ---
          _buildActionButton(
            icon: Icons.history,
            text: 'Minhas Atividades',
            textColor: textColor, // Passando a cor
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyActivityScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.edit_outlined,
            text: 'Editar Perfil',
            textColor: textColor, // Passando a cor
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
            textColor: Colors.red, // Este continua vermelho
            color: Colors.red,     // Ícone também vermelho
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color? color,
    Color? textColor,
  }) {
    // Se a cor do ícone não for passada, usa a cor do texto ou preto como fallback
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
