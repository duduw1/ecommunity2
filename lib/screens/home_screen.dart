import 'package:ecommunity/screens/marketplace/marketplace_screen.dart';
import 'package:ecommunity/screens/profile/my_activity_screen.dart'; // Import MyActivityScreen
import 'package:ecommunity/screens/profile/profile_screen.dart';
import 'package:ecommunity/screens/social/chat_list_screen.dart'; // Import ChatListScreen
import 'package:ecommunity/screens/social/social_feed_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

import 'package:ecommunity/screens/ai_assistant/ai_assistant_screen.dart';
import 'package:ecommunity/screens/auth/login_screen.dart';
import 'package:ecommunity/screens/auth/signup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title, required this.changeTheme});

  final String title;
  final VoidCallback changeTheme;

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const SocialFeedScreen(),
      const MarketplaceScreen(),
      const AiAssistantScreen(),
      const ProfileScreen(),
    ];
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getAppBarTitle(int index) {
    return widget.title;
  }

  // New Logout Logic
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();

      // Close the Drawer first
      if (mounted) Navigator.pop(context);

      // Navigate to Login Screen and remove history
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  void _openChatList() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get current Firebase User directly
    final User? user = FirebaseAuth.instance.currentUser;
    final bool isLoggedIn = user != null;

    // Use email or displayName if available, otherwise generic text
    final String displayTitle = user?.displayName ?? user?.email ?? "Visitante";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(_getAppBarTitle(_selectedIndex)),
        actions: [
          // Adicionei o botão de chat aqui
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.chat),
              tooltip: 'Minhas Conversas',
              onPressed: _openChatList,
            ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.changeTheme,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.eco,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ecommunity',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Optional: Show email in header
                  if (isLoggedIn)
                    Text(
                      displayTitle,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            if (isLoggedIn) ...[
              // === SHOW THESE ITEMS IF LOGGED IN ===
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: const Text("Meu Perfil"),
                onTap: () {
                  Navigator.pop(context);
                  // Switch to Profile Tab (Index 3)
                  setState(() {
                    _selectedIndex = 3;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.history), // Ícone de Histórico
                title: const Text("Minhas Atividades"),
                onTap: () {
                  Navigator.pop(context); // Fechar Drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyActivityScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat), // Ícone de Chat também no menu lateral
                title: const Text("Mensagens"),
                onTap: () {
                  Navigator.pop(context);
                  _openChatList();
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configurações'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sair', style: TextStyle(color: Colors.red)),
                onTap: _logout, // Call the new logout method
              ),
            ] else ...[
              // === SHOW THESE ITEMS IF NOT LOGGED IN ===
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Entrar'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add_alt_1),
                title: const Text('Criar Conta'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  );
                },
              ),
            ],
          ],
        ),
      ),
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store),
            label: 'Loja',
          ),
          NavigationDestination(
            icon: Icon(Icons.assistant_outlined),
            selectedIcon: Icon(Icons.assistant),
            label: 'IA',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
