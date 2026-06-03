import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

class PageAtmosphere extends StatelessWidget {
  const PageAtmosphere({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 32),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppTheme.pageBackgroundDark
                  : AppTheme.pageBackgroundLight,
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppTheme.pageAtmosphereDark
                    : AppTheme.pageAtmosphereLight,
              ),
            ),
          ),
        ),
        ListView(padding: padding, children: [child]),
      ],
    );
  }
}

class PageSectionHeader extends StatelessWidget {
  const PageSectionHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle != null) ...[
            Text(
              subtitle!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isDark
                    ? AppTheme.warmWhite60
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.78),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: isDark ? AppTheme.warmWhite90 : colorScheme.onSurface,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class PageSurfaceCard extends StatelessWidget {
  const PageSurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
    this.variant = PageSurfaceVariant.primary,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final PageSurfaceVariant variant;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? AppTheme.radius2xl),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isDark ? 10 : 14,
          sigmaY: isDark ? 10 : 14,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: _surfaceGradient(isDark),
            borderRadius: BorderRadius.circular(radius ?? AppTheme.radius2xl),
            border: Border.all(
              color: _borderColor(isDark),
              width: isDark ? 0.9 : 0.8,
            ),
            boxShadow: _shadow(isDark),
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }

  LinearGradient _surfaceGradient(bool isDark) {
    return switch ((variant, isDark)) {
      (PageSurfaceVariant.primary, false) => AppTheme.surfaceCardGradientLight,
      (PageSurfaceVariant.secondary, false) =>
        AppTheme.surfaceCardGradientLightAlt,
      (PageSurfaceVariant.tertiary, false) =>
        AppTheme.surfaceCardGradientLightTertiary,
      (PageSurfaceVariant.primary, true) => AppTheme.surfaceCardGradientDark,
      (PageSurfaceVariant.secondary, true) =>
        AppTheme.surfaceCardGradientDarkAlt,
      (PageSurfaceVariant.tertiary, true) =>
        AppTheme.surfaceCardGradientDarkTertiary,
    };
  }

  Color _borderColor(bool isDark) {
    return switch ((variant, isDark)) {
      (PageSurfaceVariant.primary, false) => AppTheme.surfaceBorderLight,
      (PageSurfaceVariant.secondary, false) => AppTheme.surfaceBorderLightSoft,
      (PageSurfaceVariant.tertiary, false) => AppTheme.surfaceBorderLightStrong,
      (PageSurfaceVariant.primary, true) => AppTheme.surfaceBorderDark,
      (PageSurfaceVariant.secondary, true) => AppTheme.surfaceBorderDarkSoft,
      (PageSurfaceVariant.tertiary, true) => AppTheme.surfaceBorderDarkStrong,
    };
  }

  List<BoxShadow> _shadow(bool isDark) {
    return switch ((variant, isDark)) {
      (PageSurfaceVariant.primary, false) => AppTheme.shadowCardLight,
      (PageSurfaceVariant.secondary, false) => AppTheme.shadowCardLightSoft,
      (PageSurfaceVariant.tertiary, false) => AppTheme.shadowCardLightStrong,
      (PageSurfaceVariant.primary, true) => AppTheme.shadowCardDark,
      (PageSurfaceVariant.secondary, true) => AppTheme.shadowCardDarkSoft,
      (PageSurfaceVariant.tertiary, true) => AppTheme.shadowCardDarkStrong,
    };
  }
}

enum PageSurfaceVariant { primary, secondary, tertiary }

class PageInsetPanel extends StatelessWidget {
  const PageInsetPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppTheme.surfaceInsetGradientDark
            : AppTheme.surfaceInsetGradientLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark
              ? AppTheme.surfaceBorderDarkSoft
              : AppTheme.surfaceBorderLightSoft,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.14)
                : colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class PageIconBadge extends StatelessWidget {
  const PageIconBadge({
    super.key,
    required this.icon,
    this.color,
    this.size = 40,
  });

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveColor = color ?? theme.colorScheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  effectiveColor.withValues(alpha: 0.28),
                  effectiveColor.withValues(alpha: 0.12),
                ]
              : [
                  effectiveColor.withValues(alpha: 0.18),
                  Colors.white.withValues(alpha: 0.92),
                ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark
              ? effectiveColor.withValues(alpha: 0.28)
              : effectiveColor.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: effectiveColor.withValues(alpha: isDark ? 0.18 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Icon(icon, color: effectiveColor, size: size * 0.52),
    );
  }
}

class PageListItem extends StatelessWidget {
  const PageListItem({
    super.key,
    required this.title,
    this.titleKey,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.titleStyle,
    this.enabled = true,
    this.compact = false,
  });

  final Widget? leading;
  final String title;
  final Key? titleKey;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final TextStyle? titleStyle;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 0 : 2,
          vertical: compact ? 10 : 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    key: titleKey,
                    style: (titleStyle ?? theme.textTheme.bodyLarge)?.copyWith(
                      color:
                          titleColor ??
                          titleStyle?.color ??
                          (enabled
                              ? (isDark
                                    ? AppTheme.warmWhite90
                                    : colorScheme.onSurface)
                              : colorScheme.onSurfaceVariant),
                      fontWeight: titleStyle?.fontWeight ?? FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppTheme.warmWhite60
                            : colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
      ),
    );
  }
}

class PageDivider extends StatelessWidget {
  const PageDivider({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Divider(
        height: 1,
        thickness: 0.7,
        color: isDark
            ? AppTheme.surfaceBorderDarkSoft.withValues(alpha: 0.72)
            : AppTheme.surfaceBorderLightSoft,
      ),
    );
  }
}
