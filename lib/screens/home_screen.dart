import 'package:ecommunity/AppColors.dart';
import 'package:ecommunity/screens/marketplace/marketplace_screen.dart';
import 'package:ecommunity/screens/profile/profile_screen.dart';
import 'package:ecommunity/screens/social/social_feed_screen.dart';

// import 'package:ecommunity/screens/social/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:ecommunity/screens/ai_assistant/ai_assistant_screen.dart';
import 'package:ecommunity/screens/auth/login_screen.dart';
import 'package:ecommunity/screens/auth/signup_screen.dart';

import '../models/post_model.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title, required this.changeTheme});

  final String title;
  final VoidCallback changeTheme;

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  // 1. State variable to track the current selected index
  int _selectedIndex = 0;

  // List of screens to navigate between
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      // 0: Home Feed
      SocialFeedScreen(), // Main Feed
      // 1: Marketplace (Dummy)
      MarketplaceScreen(),
      // 2: AI Assistant
      const AiAssistantScreen(),
      const ProfileScreen(),
    ];
  }

  // 2. Method to update the selected index
  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getAppBarTitle(int index) {
    return widget.title;
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionManager();
    final bool isLoggedIn = session.isLoggedIn();
    final String? userName = session.currentUser?.name;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(_getAppBarTitle(_selectedIndex)),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.changeTheme,
          ),
        ],
      ),
      drawer: Drawer(
        // Usar um ListView garante que o conteúdo possa rolar se a tela for pequena.
        child: ListView(
          // Remove qualquer preenchimento do ListView.
          padding: EdgeInsets.zero,
          children: <Widget>[
            // O cabeçalho do Drawer. Fica visualmente mais agradável.
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).primaryColor, // Usa a cor primária do seu tema
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.eco, // Ícone relacionado ao tema do app
                    color: Colors.white,
                    size: 48,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ecommunity',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            if (isLoggedIn) ...[
              // === SHOW THESE ITEMS IF THE USER IS LOGGED IN ===
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: Text(userName ?? "profile"),
                onTap: () {
                  // TODO: Navigate to the user's profile screen
                  Navigator.pop(context); // Close drawer
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  // TODO: Navigate to a settings screen
                  Navigator.pop(context); // Close drawer
                },
              ),
              const Divider(), // A visual separator
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  // --- NEW: Call the logout method ---
                  session.logout();
                  Navigator.pop(context); // Close the drawer

                  // Optional: Force the screen to rebuild to reflect the change
                  // This is important!
                  setState(() {});
                },
              ),
            ] else ...[
              // === SHOW THESE ITEMS IF THE USER IS NOT LOGGED IN ===
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

      // 3. Use IndexedStack to display the selected screen while preserving its state
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),

      // 4. Use the modern NavigationBar widget
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected, // New M3 callback name
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store),
            label: 'Store',
          ),
          NavigationDestination(
            icon: Icon(Icons.assistant_outlined),
            selectedIcon: Icon(Icons.assistant),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Custom widget for displaying a single post card
