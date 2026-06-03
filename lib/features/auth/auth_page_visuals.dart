import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

/// Full-screen warm gradient background with decorative accents
/// for the authentication flow pages (sign-in, register, profile setup).
///
/// All visual values are consumed from [AppTheme] tokens.
class AuthPageBackground extends StatelessWidget {
  const AuthPageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppTheme.authBackgroundDark
            : AppTheme.authBackgroundLight,
      ),
      child: Stack(
        children: [
          // Top-right decorative circle
          Positioned(
            top: -40,
            right: -30,
            child: _DecorativeCircle(
              diameter: 180,
              color: (isDark
                      ? AppTheme.authAccentCircleDark1
                      : AppTheme.authAccentCircleLight1)
                  .withValues(alpha: isDark ? 0.35 : 0.45),
            ),
          ),
          // Bottom-left decorative circle
          Positioned(
            bottom: -50,
            left: -40,
            child: _DecorativeCircle(
              diameter: 160,
              color: (isDark
                      ? AppTheme.authAccentCircleDark2
                      : AppTheme.authAccentCircleLight2)
                  .withValues(alpha: isDark ? 0.30 : 0.40),
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
