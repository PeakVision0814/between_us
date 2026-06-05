import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ─── Legacy constants (kept for existing references) ────────────────
  static const Color ink = Color(0xFF231F20);
  static const Color paper = Color(0xFFFFF8F1);
  static const Color midnight = Color(0xFF161314);
  static const Color nightCard = Color(0xFF221E20);
  static const Color blush = Color(0xFFE86F64);
  static const Color berry = Color(0xFF7D3B52);
  static const Color mint = Color(0xFF5B9A8B);
  static const Color gold = Color(0xFFE1A955);

  // ─── Light mode palette ────────────────────────────────────────────
  static const Color cream = Color(0xFFFFFBF7);
  static const Color creamDark = Color(0xFFF6EDE3);
  static const Color blushLight = Color(0xFFF3C6CB);
  static const Color blushAccent = Color(0xFFDC8D95);
  static const Color peach = Color(0xFFF0C8A8);
  static const Color peachLight = Color(0xFFF8DFC9);
  static const Color fog = Color(0xFFD8C8E0);
  static const Color fogLight = Color(0xFFEDE5F1);
  static const Color sage = Color(0xFF7DA898);
  static const Color sageLight = Color(0xFFC8DCD4);
  static const Color warmGray50 = Color(0xFFF8F3EE);
  static const Color warmGray100 = Color(0xFFEFE7DF);
  static const Color warmGray200 = Color(0xFFE0D5CA);
  static const Color warmGray400 = Color(0xFFB8A99A);
  static const Color warmGray600 = Color(0xFF877568);
  static const Color warmGray800 = Color(0xFF524440);
  static const Color warmWhite = Color(0xFFFFFDFB);

  // ─── Dark mode palette ─────────────────────────────────────────────
  static const Color deepNight = Color(0xFF161218);
  static const Color nightSurface = Color(0xFF1E1A22);
  static const Color nightElevated = Color(0xFF262230);
  static const Color nightMuted = Color(0xFF383440);
  static const Color darkBlush = Color(0xFF4A3038);
  static const Color darkBlushAccent = Color(0xFFB87A82);
  static const Color darkPeach = Color(0xFFE8C0A0);
  static const Color darkFog = Color(0xFF8A7898);
  static const Color darkSage = Color(0xFF728E82);
  static const Color nightBorder = Color(0xFF3A3540);
  static const Color nightBorderLight = Color(0xFF4A4550);
  static const Color warmWhite90 = Color(0xFFF0E8E0);
  static const Color warmWhite60 = Color(0xFFB8AEA2);
  static const Color warmWhite25 = Color(0xFF6A6058);

  // ─── Semantic colors ───────────────────────────────────────────────
  static const Color success = Color(0xFF5B9A8B);
  static const Color successDark = Color(0xFF72B8A6);
  static const Color warning = Color(0xFFE1A955);
  static const Color warningDark = Color(0xFFF0C070);

  // ─── Us-page hero & surface colors ──────────────────────────────────
  static const Color heroBlushLight = Color(0xFFF8E0E4);
  static const Color heroPeachLight = Color(0xFFFBE8D8);
  static const Color heroFogLight = Color(0xFFEDE2F2);
  static const Color heroCreamOverlay = Color(0xFFFDF8F3);

  static const Color heroDeepPurple = Color(0xFF1C1428);
  static const Color heroNightAccent = Color(0xFF2A1E38);
  static const Color heroGlowPurple = Color(0xFF6E4A88);
  static const Color heroGlowBlush = Color(0xFFB87A88);

  static const Color cardSurfaceLight = Color(0xFFFFFDFB);
  static const Color cardBorderLight = Color(0x1A000000);
  static const Color cardBorderDark = Color(0x30FFFFFF);
  static const Color surfaceBorderLight = Color(0x20D8CABC);
  static const Color surfaceBorderLightSoft = Color(0x30E7DBD0);
  static const Color surfaceBorderLightStrong = Color(0x3AD8C6BA);
  static const Color surfaceBorderDark = Color(0x32F6CCFF);
  static const Color surfaceBorderDarkSoft = Color(0x24D6B7EA);
  static const Color surfaceBorderDarkStrong = Color(0x44FF8EC5);

  // ─── Gradients ─────────────────────────────────────────────────────
  static const LinearGradient pageBackgroundLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFBF7), Color(0xFFFEF7F0), Color(0xFFFFFCF9)],
    stops: [0, 0.4, 1],
  );

  static const LinearGradient pageBackgroundDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF110D17), Color(0xFF17121F), Color(0xFF0D0A12)],
    stops: [0, 0.45, 1],
  );

  static const RadialGradient pageAtmosphereLight = RadialGradient(
    center: Alignment(-0.7, -0.92),
    radius: 1.15,
    colors: [Color(0x36F7CCD1), Color(0x18F6E2C8), Color(0x00FFFFFF)],
    stops: [0, 0.52, 1],
  );

  static const RadialGradient pageAtmosphereDark = RadialGradient(
    center: Alignment(0.45, -0.82),
    radius: 1.08,
    colors: [Color(0x386E4A88), Color(0x14251A34), Color(0x000D0A12)],
    stops: [0, 0.56, 1],
  );

  static const LinearGradient authBackgroundLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFDF2EF), Color(0xFFFDF8F3)],
  );

  static const LinearGradient authBackgroundDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1520), Color(0xFF1E1A22)],
  );

  static const LinearGradient heroGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [heroBlushLight, heroPeachLight, heroFogLight],
  );

  static const LinearGradient heroGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [heroDeepPurple, heroNightAccent],
  );

  static const RadialGradient heroAtmosphereLight = RadialGradient(
    center: Alignment(0.18, -0.18),
    radius: 0.95,
    colors: [Color(0x66FFFFFF), Color(0x24FFF6F2), Color(0x00FFFFFF)],
    stops: [0, 0.55, 1],
  );

  static const RadialGradient heroAtmosphereDark = RadialGradient(
    center: Alignment(0.12, -0.08),
    radius: 0.9,
    colors: [Color(0x30F58AB1), Color(0x186E4A88), Color(0x001C1428)],
    stops: [0, 0.58, 1],
  );

  static const LinearGradient surfaceCardGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFEFD), Color(0xFFFFF6EF)],
  );

  static const LinearGradient surfaceCardGradientLightAlt = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFCFA), Color(0xFFFDF4EC)],
  );

  static const LinearGradient surfaceCardGradientLightTertiary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFDFB), Color(0xFFFCEFE9)],
  );

  static const LinearGradient surfaceCardGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF201A28), Color(0xFF17131F)],
  );

  static const LinearGradient surfaceCardGradientDarkAlt = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF231D2D), Color(0xFF16121D)],
  );

  static const LinearGradient surfaceCardGradientDarkTertiary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF281F31), Color(0xFF17121D)],
  );

  static const LinearGradient surfaceInsetGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFAF6), Color(0xFFFDF1EA)],
  );

  static const LinearGradient surfaceInsetGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF251C2F), Color(0xFF1A1422)],
  );

  // ─── Auth decorative accents ───────────────────────────────────────
  static const Color authAccentCircleLight1 = Color(0xFFEACFD5);
  static const Color authAccentCircleLight2 = Color(0xFFF5DFC8);
  static const Color authAccentCircleDark1 = Color(0xFF3D2E42);
  static const Color authAccentCircleDark2 = Color(0xFF2E2840);

  // ─── Spacing ───────────────────────────────────────────────────────
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 20;
  static const double space2xl = 24;
  static const double space3xl = 32;
  static const double space4xl = 48;

  // ─── Border radius ─────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radius2xl = 22;
  static const double radiusFull = 999;

  // ─── Shadow ────────────────────────────────────────────────────────
  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 2), blurRadius: 8),
  ];

  static List<BoxShadow> shadowHeroLight = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 40,
      offset: const Offset(0, 20),
    ),
  ];

  static List<BoxShadow> shadowHeroDark = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 40,
      offset: const Offset(0, 20),
    ),
  ];

  static const List<BoxShadow> shadowCardLight = [
    BoxShadow(color: Color(0x08000000), offset: Offset(0, 2), blurRadius: 12),
  ];

  static const List<BoxShadow> shadowCardLightSoft = [
    BoxShadow(
      color: Color(0x0AEECEC4),
      offset: Offset(0, 12),
      blurRadius: 24,
      spreadRadius: -16,
    ),
  ];

  static const List<BoxShadow> shadowCardLightStrong = [
    BoxShadow(
      color: Color(0x14E8CDC8),
      offset: Offset(0, 14),
      blurRadius: 28,
      spreadRadius: -18,
    ),
    BoxShadow(color: Color(0x08000000), offset: Offset(0, 4), blurRadius: 12),
  ];

  static const List<BoxShadow> shadowCardDark = [
    BoxShadow(color: Color(0x187040A0), offset: Offset(0, 0), blurRadius: 12),
  ];

  static const List<BoxShadow> shadowCardDarkSoft = [
    BoxShadow(
      color: Color(0x205F3A8B),
      offset: Offset(0, 14),
      blurRadius: 26,
      spreadRadius: -18,
    ),
  ];

  static const List<BoxShadow> shadowCardDarkStrong = [
    BoxShadow(
      color: Color(0x246E3E95),
      offset: Offset(0, 16),
      blurRadius: 30,
      spreadRadius: -18,
    ),
    BoxShadow(
      color: Color(0x18F086B6),
      offset: Offset(0, 0),
      blurRadius: 18,
      spreadRadius: -12,
    ),
  ];

  // ─── Theme builders ────────────────────────────────────────────────

  static ThemeData get light {
    return _buildTheme(
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFFCC6B73),
        onPrimary: warmWhite,
        primaryContainer: Color(0xFFF5DDE0),
        onPrimaryContainer: Color(0xFF3E1520),
        secondary: sage,
        onSecondary: warmWhite,
        secondaryContainer: sageLight,
        onSecondaryContainer: Color(0xFF1E3530),
        tertiary: fog,
        onTertiary: warmWhite,
        tertiaryContainer: fogLight,
        onTertiaryContainer: Color(0xFF2E2438),
        error: Color(0xFFB3261E),
        onError: Colors.white,
        errorContainer: Color(0xFFF9DEDC),
        onErrorContainer: Color(0xFF410E0B),
        surface: cream,
        onSurface: warmGray800,
        onSurfaceVariant: warmGray600,
        outline: warmGray200,
        outlineVariant: warmGray100,
        shadow: Color(0x0A000000),
        surfaceContainerHighest: warmGray100,
        surfaceContainerHigh: warmGray50,
        surfaceContainer: warmWhite,
      ),
      scaffoldColor: cream,
      cardColor: warmWhite,
      navBackground: Colors.white,
      navIndicatorColor: const Color(0xFFF0D0D4),
    );
  }

  static ThemeData get dark {
    return _buildTheme(
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFFE8A8B0),
        onPrimary: Color(0xFF3E1520),
        primaryContainer: darkBlush,
        onPrimaryContainer: Color(0xFFF5DDE0),
        secondary: Color(0xFF8AB8A8),
        onSecondary: Color(0xFF1E3530),
        secondaryContainer: Color(0xFF2E4840),
        onSecondaryContainer: sageLight,
        tertiary: Color(0xFFB8A0C8),
        onTertiary: Color(0xFF2E2438),
        tertiaryContainer: Color(0xFF382848),
        onTertiaryContainer: fogLight,
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF601410),
        errorContainer: Color(0xFF8C1D18),
        onErrorContainer: Color(0xFFF9DEDC),
        surface: nightSurface,
        onSurface: warmWhite90,
        onSurfaceVariant: warmWhite60,
        outline: nightBorder,
        outlineVariant: nightBorderLight,
        shadow: Color(0x44000000),
        surfaceContainerHighest: nightMuted,
        surfaceContainerHigh: nightElevated,
        surfaceContainer: nightSurface,
      ),
      scaffoldColor: deepNight,
      cardColor: nightElevated,
      navBackground: const Color(0xFF1B1719),
      navIndicatorColor: darkBlush,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldColor,
    required Color cardColor,
    required Color navBackground,
    required Color navIndicatorColor,
  }) {
    final isLight = colorScheme.brightness == Brightness.light;
    final textColor = colorScheme.onSurface;
    final mutedTextColor = colorScheme.onSurfaceVariant;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldColor,

      // ── AppBar ───────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
          statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
        ),
      ),

      // ── Cards ────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius2xl),
          side: BorderSide(
            color: isLight
                ? colorScheme.outlineVariant
                : colorScheme.outline.withValues(alpha: 0.35),
          ),
        ),
      ),

      // ── Filled buttons ───────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius2xl),
          ),
        ),
      ),

      // ── Outlined buttons ─────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(color: colorScheme.outline),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius2xl),
          ),
        ),
      ),

      // ── Text buttons ─────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
        ),
      ),

      // ── Chips ────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        selectedColor: isLight ? blushLight : darkBlush,
        labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        secondaryLabelStyle: TextStyle(
          color: isLight ? const Color(0xFF6B3A42) : const Color(0xFFEACDD2),
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // ── Input fields ─────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? warmGray50 : nightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius2xl),
          borderSide: BorderSide(color: isLight ? warmGray200 : nightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius2xl),
          borderSide: BorderSide(color: isLight ? warmGray200 : nightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius2xl),
          borderSide: BorderSide(
            color: colorScheme.primary.withValues(alpha: isLight ? 0.55 : 0.45),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius2xl),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius2xl),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        labelStyle: TextStyle(color: mutedTextColor, fontSize: 14),
        hintStyle: TextStyle(
          color: mutedTextColor.withValues(alpha: 0.65),
          fontSize: 14,
        ),
      ),

      // ── ListTile ─────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        textColor: textColor,
      ),

      // ── Navigation bar ───────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        indicatorColor: navIndicatorColor.withValues(
          alpha: isLight ? 0.45 : 0.35,
        ),
        backgroundColor: navBackground,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : mutedTextColor,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),

      // ── Divider ──────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 0.5,
      ),

      // ── Typography ───────────────────────────────────────────────
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: textColor,
          fontSize: 30,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
        headlineSmall: TextStyle(
          color: textColor,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          height: 1.25,
        ),
        titleLarge: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
        titleSmall: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
        bodyLarge: TextStyle(color: textColor, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(
          color: textColor.withValues(alpha: 0.88),
          height: 1.45,
        ),
        bodySmall: TextStyle(color: mutedTextColor, height: 1.4),
        labelLarge: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );
  }
}
