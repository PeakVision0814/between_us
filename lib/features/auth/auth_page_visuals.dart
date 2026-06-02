import 'package:flutter/material.dart';

/// Shared visual utilities for the authentication flow pages.
///
/// Provides a warm, soft gradient background with decorative elements
/// and color constants for auth-specific components.
class AuthPageBackground extends StatelessWidget {
  const AuthPageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF1A1520),
                  Color(0xFF1E1A22),
                ]
              : const [
                  Color(0xFFFDF2EF),
                  Color(0xFFFDF8F3),
                ],
        ),
      ),
      child: Stack(
        children: [
          // Top-right decorative circle
          Positioned(
            top: -40,
            right: -30,
            child: _DecorativeCircle(
              diameter: 180,
              color: isDark
                  ? const Color(0xFF3D2E42).withValues(alpha: 0.35)
                  : const Color(0xFFEACFD5).withValues(alpha: 0.45),
            ),
          ),
          // Bottom-left decorative circle
          Positioned(
            bottom: -50,
            left: -40,
            child: _DecorativeCircle(
              diameter: 160,
              color: isDark
                  ? const Color(0xFF2E2840).withValues(alpha: 0.30)
                  : const Color(0xFFF5DFC8).withValues(alpha: 0.40),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({
    required this.diameter,
    required this.color,
  });

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

/// Color constants for auth-specific components.
///
/// Used by FirstProfileSetupScreen for ChoiceChip styling
/// and other auth-only visual elements.
class AuthColors {
  AuthColors._();

  // Chip colors (light mode)
  static const Color chipSelectedLight = Color(0xFFF5DDE0);
  static const Color chipSelectedTextLight = Color(0xFF6B3A42);
  static const Color chipBorderLight = Color(0x33D8AEB6);

  // Chip colors (dark mode)
  static const Color chipSelectedDark = Color(0xFF3A2530);
  static const Color chipSelectedTextDark = Color(0xFFEACDD2);
  static const Color chipBorderDark = Color(0x33BFA4A9);
}
