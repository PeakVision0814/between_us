import 'package:flutter/material.dart';

class AppTheme {
  static const Color ink = Color(0xFF231F20);
  static const Color paper = Color(0xFFFFF8F1);
  static const Color midnight = Color(0xFF161314);
  static const Color nightCard = Color(0xFF221E20);
  static const Color blush = Color(0xFFE86F64);
  static const Color berry = Color(0xFF7D3B52);
  static const Color mint = Color(0xFF5B9A8B);
  static const Color gold = Color(0xFFE1A955);

  static ThemeData get light {
    return _buildTheme(
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: blush,
        onPrimary: Colors.white,
        secondary: mint,
        onSecondary: Colors.white,
        tertiary: gold,
        onTertiary: ink,
        error: Color(0xFFB3261E),
        onError: Colors.white,
        surface: paper,
        onSurface: ink,
        outline: Color(0x33231F20),
        shadow: Color(0x1F231F20),
      ),
      cardColor: Colors.white,
      scaffoldColor: paper,
      navBackground: Colors.white,
    );
  }

  static ThemeData get dark {
    return _buildTheme(
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFFFFA89F),
        onPrimary: midnight,
        secondary: Color(0xFF95D0C3),
        onSecondary: midnight,
        tertiary: Color(0xFFF4C883),
        onTertiary: midnight,
        error: Color(0xFFFFB4AB),
        onError: midnight,
        surface: midnight,
        onSurface: Color(0xFFF8EFE8),
        outline: Color(0x33FFF8F1),
        shadow: Color(0x66000000),
      ),
      cardColor: nightCard,
      scaffoldColor: midnight,
      navBackground: const Color(0xFF1B1719),
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color cardColor,
    required Color scaffoldColor,
    required Color navBackground,
  }) {
    final isLight = colorScheme.brightness == Brightness.light;
    final textColor = colorScheme.onSurface;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldColor,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(color: colorScheme.outline),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        textColor: textColor,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        indicatorColor: colorScheme.primary.withValues(
          alpha: isLight ? 0.16 : 0.24,
        ),
        backgroundColor: navBackground,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : textColor,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outline),
      textTheme: TextTheme(
        headlineSmall: TextStyle(
          color: textColor,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(color: textColor, height: 1.45),
        bodySmall: TextStyle(
          color: textColor.withValues(alpha: 0.75),
          height: 1.4,
        ),
      ),
    );
  }
}
