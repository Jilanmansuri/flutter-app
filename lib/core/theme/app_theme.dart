import 'package:flutter/material.dart';

class AppTheme {
  // Brand color guidelines
  static const Color primaryDark = Color(0xFF0F172A); // Slate 900
  static const Color primaryAccent = Color(0xFF6366F1); // Indigo 500
  static const Color secondaryAccent = Color(0xFF10B981); // Emerald 500
  static const Color dangerAccent = Color(0xFFEF4444); // Red 500
  static const Color warningAccent = Color(0xFFF59E0B); // Amber 500
  
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryAccent,
      brightness: Brightness.light,
      primary: primaryAccent,
      secondary: secondaryAccent,
      error: dangerAccent,
      surface: const Color(0xFFF8FAFC), // Slate 50
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24.0)),
        side: BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: primaryDark),
      titleTextStyle: TextStyle(
        color: primaryDark,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontWeight: FontWeight.w800, color: primaryDark, letterSpacing: -1.0),
      titleLarge: TextStyle(fontWeight: FontWeight.w700, color: primaryDark, letterSpacing: -0.5),
      bodyLarge: TextStyle(color: Color(0xFF334155)),
      bodyMedium: TextStyle(color: Color(0xFF64748B)),
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryAccent,
      brightness: Brightness.dark,
      primary: primaryAccent,
      secondary: secondaryAccent,
      error: dangerAccent,
      surface: const Color(0xFF0B0F19), // Deeper Slate
    ),
    scaffoldBackgroundColor: const Color(0xFF070A13),
    cardTheme: const CardThemeData(
      color: Color(0xFF111827), // Gray 900
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24.0)),
        side: BorderSide(color: Color(0xFF1F2937), width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1.0),
      titleLarge: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
      bodyLarge: TextStyle(color: Color(0xFFE2E8F0)),
      bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
    ),
  );

  // Gradient definitions for UI cards
  static const List<Color> mainCardGradient = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF4F46E5), // Indigo dark
  ];

  static const List<Color> greenGradient = [
    Color(0xFF10B981), // Emerald
    Color(0xFF059669),
  ];

  static const List<Color> orangeGradient = [
    Color(0xFFF59E0B), // Amber
    Color(0xFFD97706),
  ];

  static const List<Color> redGradient = [
    Color(0xFFEF4444), // Red
    Color(0xFFDC2626),
  ];

  static const List<Color> darkGlassGradient = [
    Color(0x1F293780),
    Color(0x11182740),
  ];
}
