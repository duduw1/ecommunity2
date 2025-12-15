import 'package:ecommunity/screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure that Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const App());
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

  // --- Placeholder colors (can be moved to a dedicated theme file) ---
  final Color primaryColor = Colors.green;
  final Color secondaryColor = Colors.teal;
  final Color lightBackgroundColor = const Color(0xFFF0F0F0);
  final Color darkBackgroundColor = const Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ecommunity',
      debugShowCheckedModeBanner: false, // Opcional: Remove a faixa de debug
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
          primary: primaryColor,
          surface: lightBackgroundColor,
          secondary: secondaryColor,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
          primary: primaryColor,
          surface: darkBackgroundColor,
          secondary: secondaryColor,
        ),
      ),
      themeMode: _theme,
      home: HomeScreen(title: 'Ecommunity', changeTheme: changeTheme),
    );
  }
}
