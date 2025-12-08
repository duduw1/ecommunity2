import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
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
  // Variable to store the logged-in user data (from your model).
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Loads user data directly from Firestore using the Auth UID.
  Future<void> _loadUserData() async {
    try {
      // 1. Get the current logged-in user from Firebase Auth
      final firebase_auth.User? authUser = firebase_auth.FirebaseAuth.instance.currentUser;

      if (authUser == null) {
        // Not logged in
        setState(() {
          _currentUser = null;
          _isLoading = false;
        });
        return;
      }

      // 2. Fetch the user document from Firestore
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .get();

      if (doc.exists) {
        // 3. Convert Firestore data to your User model
        setState(() {
          _currentUser = User.fromFirestore(doc);
          _isLoading = false;
        });
      } else {
        setState(() {
          _currentUser = null; // User authenticated, but no profile data found
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

  /// Executes logout logic.
  Future<void> _logout() async {
    try {
      // 1. Sign out from Firebase
      await firebase_auth.FirebaseAuth.instance.signOut();

      // 2. Navigate back to LoginScreen and clear the stack
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
          ? _buildErrorView()
          : _buildProfileView(),
    );
  }

  /// Builds the main profile view.
  Widget _buildProfileView() {
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
            icon: Icons.edit_outlined,
            text: 'Editar Perfil',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidade de edição a ser implementada.')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.logout,
            text: 'Sair (Logout)',
            color: Colors.red,
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  /// Helper widget for action buttons
  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  /// Builds an error view if user data cannot be loaded.
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