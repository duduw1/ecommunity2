import 'package:ecommunity/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:ecommunity/ai_assistant.dart';
import 'package:ecommunity/about.dart';
import 'package:ecommunity/signup.dart';
import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const App());
}

// Data model for a social media post
class Post {
  final String username;
  final String userAvatarUrl;
  final String postImageUrl;
  final String caption;

  Post({
    required this.username,
    required this.userAvatarUrl,
    required this.postImageUrl,
    required this.caption,
  });
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  ThemeMode _theme = ThemeMode.dark;

  void changeTheme() {
    setState(() {
      _theme = _theme == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  // --- Assuming AppColors provides these colors, using placeholders if not defined ---
  final Color primaryColor = Colors.green;
  final Color secondaryColor = Colors.teal;
  final Color lightBackgroundColor = const Color(0xFFF0F0F0);
  final Color darkBackgroundColor = const Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
          primary: primaryColor, // AppColors.primary
          surface: lightBackgroundColor, // AppColors.lightBackground
          secondary: secondaryColor, // AppColors.secondary
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
          primary: primaryColor, // AppColors.primary
          surface: darkBackgroundColor, // AppColors.background
          secondary: secondaryColor, // AppColors.secondary
        ),
      ),
      themeMode: _theme,
      home: MainScreenWrapper(title: 'Ecommunity', changeTheme: changeTheme),
    );
  }
}

// Renamed HomePage to MainScreenWrapper to better reflect its function
class MainScreenWrapper extends StatefulWidget {
  const MainScreenWrapper({super.key, required this.title, required this.changeTheme});

  final String title;
  final VoidCallback changeTheme;

  @override
  State<MainScreenWrapper> createState() => _MainScreenWrapperState();
}

class _MainScreenWrapperState extends State<MainScreenWrapper> {
  // 1. State variable to track the current selected index
  int _selectedIndex = 0;

  // Dummy data for the posts (kept here as it's the main screen's content)
  final List<Post> posts = [
    Post(
      username: 'ecofriendly',
      userAvatarUrl: 'https://i.pravatar.cc/150?img=1',
      postImageUrl:
      'https://media.istockphoto.com/id/1659684092/pt/foto/a-view-up-into-the-trees-direction-sky.jpg?s=1024x1024&w=is&k=20&c=w_bm_55yc8QGZwvdAHvr7ByWnihRyPDKGaT8OUMXl3w=',
      caption:
      '“Just swapped out all my plastic bags for reusable cotton ones! Small steps make a big impact 🌍♻️ #PlasticFree #Sustainability”',
    ),
    Post(
      username: 'eco',
      userAvatarUrl: 'https://i.pravatar.cc/150?img=2',
      postImageUrl:
      'https://cdn.pixabay.com/photo/2023/02/14/04/39/volunteer-7788809_1280.jpg',
      caption:
      'Did you know glass can be recycled endlessly without losing quality? Make sure to clean your jars before recycling!',
    ),
    Post(
      username: 'proRecycler',
      userAvatarUrl:
      'https://images.pexels.com/photos/1053845/pexels-photo-1053845.jpeg',
      postImageUrl:
      'https://media.istockphoto.com/id/1342229204/pt/foto/a-lake-in-the-shape-of-a-recycling-sign-in-the-middle-of-untouched-nature-an-ecological.jpg?s=1024x1024&w=is&k=20&c=Q-Cvz4PFNrktJnUxFVNeBIh-LkapsjjYBfYGXvZc-RU=',
      caption:
      'Upcycled my old t-shirts into reusable shopping bags! Who else loves DIY projects?',
    ),
  ];

  // List of screens to navigate between
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      // 0: Home Feed
      HomePageContent(posts: posts), // Main Feed
      // 1: Marketplace (Dummy)
      const Center(child: Text('🛒 Marketplace Screen', style: TextStyle(fontSize: 24))),
      // 2: AI Assistant
      const AiAssistantScreen(),
      // 3: Profile/Login
      const LoginWidget(),
      // 4: About
      const AboutPage(),
    ];
  }

  // 2. Method to update the selected index
  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return widget.title; // 'Ecommunity'
      case 1:
        return 'Marketplace';
      case 2:
        return 'AI Assistant';
      case 3:
        return 'Profile/Sign Up';
      case 4:
        return 'About';
      default:
        return widget.title;
    }
  }

  @override
  Widget build(BuildContext context) {
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
      // 3. Use IndexedStack to display the selected screen while preserving its state
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),

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
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'About',
          ),
        ],
      ),
    );
  }
}

// Extracted the ListView content into a separate widget for clarity
class HomePageContent extends StatelessWidget {
  final List<Post> posts;

  const HomePageContent({super.key, required this.posts});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return PostCard(post: posts[index]);
      },
    );
  }
}

// Custom widget for displaying a single post card
class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                CircleAvatar(backgroundImage: NetworkImage(post.userAvatarUrl)),
                const SizedBox(width: 8.0),
                Text(
                  post.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Image.network(post.postImageUrl),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(post.caption),
          ),
        ],
      ),
    );
  }
}