import 'package:flutter/material.dart';

class AppColors {
  // Greens
  static const Color primary = Color(0xFF2E7D32); // Main dark green
  static const Color primaryLight = Color(0xFF81C784); // Lighter green
  static const Color accent = Colors.green; // Standard green
  static const Color backgroundLight = Color(0xFFF1F8E9); // Very light green background
  static const Color cardBackground = Color(0xFFE8F5E8); // Light green for cards

  // Grays & Whites
  static const Color textSecondary = Color(0xFF666666);   // Secondary text
  static const Color borderLight = Color(0xFFEEEEEE);     // Light gray for borders
  static const Color backgroundGray = Color(0xFFF8F9FA);  // Very light gray background
  static const Color textWhite = Colors.white;            // White text
  static const Color whiteTransparent70 = Color(0xB3FFFFFF); // Semi-transparent white
  static const Color whiteTransparent30 = Color(0x4DFFFFFF); // More transparent white
  static const Color whiteDivider = Color(0x33FFFFFF);      // Transparent white for dividers

  // Accent Colors
  static const Color accentPurple = Colors.purple;
  static const Color cardPurple = Color(0xFFF3E5F5);
  static const Color accentBlue = Colors.blue;
  static const Color cardBlue = Color(0xFFE3F2FD);
  static const Color cardGreen = Color(0xFFE8F8F5);

  // Deprecated colors (from the old palette)
  static const Color secondary_old = Color.fromRGBO(158, 26, 26, 1);
  static const Color background_old = Color.fromRGBO(23, 23, 23, 1);
  static const Color lightBackground_old = Color.fromRGBO(232, 232, 232, 1);
}
