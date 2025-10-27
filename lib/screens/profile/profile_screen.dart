import 'package:ecommunity/models/user_model.dart';
import 'package:ecommunity/providers/auth_provider.dart'; // Importe seu SessionManager
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Variável para armazenar os dados do usuário logado.
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Carrega os dados do usuário a partir do SessionManager.
  void _loadUserData() {
    // Acessa a instância singleton do SessionManager para obter o usuário atual.
    final user = SessionManager().currentUser;
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
  }

  /// Executa o processo de logout.
  Future<void> _logout() async {
    // Chama o método de logout do seu SessionManager.
    await SessionManager().logout();

    // Após o logout, navega para a tela de autenticação e remove todas as
    // telas anteriores da pilha, para que o usuário не possa voltar para a tela de perfil.
    // if (mounted) {
    //   Navigator.of(context).pushAndRemoveUntil(
    //     MaterialPageRoute(builder: (context) => const AuthWrapper()),
    //         (Route<dynamic> route) => false, // Este predicado remove todas as rotas.
    //   );
    // }
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
          ? _buildErrorView() // Mostra uma mensagem se os dados não puderem ser carregados
          : _buildProfileView(),
    );
  }

  /// Constrói a visualização principal do perfil do usuário.
  Widget _buildProfileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 60,
            backgroundColor: Colors.green,
            child: Icon(
              Icons.person,
              size: 60,
              color: Colors.white,
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

          // --- Botões de Ação ---
          _buildActionButton(
            icon: Icons.edit_outlined,
            text: 'Editar Perfil',
            onTap: () {
              // TODO: Navegar para uma tela de edição de perfil.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Funcionalidade de edição a ser implementada.')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.logout,
            text: 'Sair (Logout)',
            color: Colors.red, // Destaque para a ação de sair
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  /// Constrói um item de menu de ação reutilizável.
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

  /// Constrói uma visualização de erro caso os dados do usuário não sejam encontrados.
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