import 'package:ecommunity/screens/about_screen.dart';
import 'package:ecommunity/screens/eco_calendar_screen.dart';
import 'package:ecommunity/screens/marketplace/marketplace_screen.dart';
import 'package:ecommunity/screens/points_exchange_screen.dart';
import 'package:ecommunity/screens/profile/my_activity_screen.dart';
import 'package:ecommunity/screens/profile/profile_screen.dart';
import 'package:ecommunity/screens/recycling_map_screen.dart'; // Import Map
import 'package:ecommunity/screens/social/chat_list_screen.dart';
import 'package:ecommunity/screens/social/notifications_screen.dart';
import 'package:ecommunity/screens/social/social_feed_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.pop(context);
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

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final bool isLoggedIn = user != null;
    final String displayTitle = user?.displayName ?? user?.email ?? "Visitante";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(_getAppBarTitle(_selectedIndex)),
        actions: [
          if (isLoggedIn) ...[
            IconButton(
              icon: const Icon(Icons.chat),
              tooltip: 'Minhas Conversas',
              onPressed: _openChatList,
            ),
            IconButton(
              icon: const Icon(Icons.notifications),
              tooltip: 'Notificações',
              onPressed: _openNotifications,
            ),
          ],
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
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: const Text("Meu Perfil"),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedIndex = 3;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text("Minhas Atividades"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyActivityScreen()),
                  );
                },
              ),
              
              // ITENS ADICIONAIS
              ListTile(
                leading: const Icon(Icons.card_giftcard, color: Colors.green),
                title: const Text("Troca de Pontos"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PointsExchangeScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: const Text("Calendário Ecológico"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EcoCalendarScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.map_outlined, color: Colors.orange), // Novo item Mapa
                title: const Text("Mapa de Reciclagem"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RecyclingMapScreen()),
                  );
                },
              ),
              // FIM ITENS ADICIONAIS

              ListTile(
                leading: const Icon(Icons.chat),
                title: const Text("Mensagens"),
                onTap: () {
                  Navigator.pop(context);
                  _openChatList();
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text("Notificações"),
                onTap: () {
                  Navigator.pop(context);
                  _openNotifications();
                },
              ),
              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: const Text('Alternar Tema'),
                onTap: () {
                  widget.changeTheme();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Sobre o App'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sair', style: TextStyle(color: Colors.red)),
                onTap: _logout,
              ),
            ] else ...[
              // VISITANTES TAMBÉM PODEM VER MAPA E CALENDÁRIO
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: const Text("Calendário Ecológico"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EcoCalendarScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.map_outlined, color: Colors.orange),
                title: const Text("Mapa de Reciclagem"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RecyclingMapScreen()),
                  );
                },
              ),
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
              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: const Text('Alternar Tema'),
                onTap: () {
                  widget.changeTheme();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Sobre o App'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutScreen()),
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
