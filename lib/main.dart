// import 'package:ecommunity/AppColors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommunity/screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ecommunity/screens/ai_assistant/ai_assistant_screen.dart';
import 'package:ecommunity/about.dart';
import 'package:ecommunity/signup.dart';
import 'dart:io';

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
      home: HomeScreen(title: 'Ecommunity', changeTheme: changeTheme),
    );
  }
}

