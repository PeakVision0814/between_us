import 'package:flutter/material.dart';

class AppTheme {
  static const Color ink = Color(0xFF231F20);
  static const Color paper = Color(0xFFFFF8F1);
  static const Color blush = Color(0xFFE86F64);
  static const Color berry = Color(0xFF7D3B52);
  static const Color mint = Color(0xFF5B9A8B);
  static const Color gold = Color(0xFFE1A955);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: blush,
      brightness: Brightness.light,
      surface: paper,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: paper,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: ink.withValues(alpha: 0.08)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        indicatorColor: blush.withValues(alpha: 0.16),
        backgroundColor: Colors.white,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? berry : ink,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: ink,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          color: ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(color: ink, height: 1.45),
      ),
    );
  }
}
