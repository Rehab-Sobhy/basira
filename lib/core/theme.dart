import 'package:flutter/material.dart';

class AppTheme {
  // Premium Color Palette
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color accent = Color(0xFF10B981); // Emerald
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B); // Slate 800
  static const Color primaryText = Colors.white;
  static const Color secondaryText = Color(0xFF94A3B8); // Slate 400
  
  static const Color button1 = Color(0xFF6366F1);
  static const Color button2 = Color(0xFF8B5CF6);
  static const Color button3 = Color(0xFFEC4899);
  static const Color emergencyButton = Color(0xFFEF4444);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        onSurface: primaryText,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: primaryText,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: primaryText, fontSize: 36, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: primaryText, fontSize: 28, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: primaryText, fontSize: 20),
        bodyMedium: TextStyle(color: secondaryText, fontSize: 16),
      ),
    );
  }
}
