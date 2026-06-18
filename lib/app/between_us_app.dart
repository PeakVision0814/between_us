import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_controller.dart';
import 'app_shell.dart';
import 'app_strings.dart';
import 'app_theme.dart';
import '../features/auth/email_otp_sign_in_screen.dart';
import '../features/auth/email_register_screen.dart';
import '../features/auth/first_profile_setup_screen.dart';

class BetweenUsApp extends StatelessWidget {
  const BetweenUsApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final brightness = controller.themeMode == ThemeMode.dark
              ? Brightness.dark
              : controller.themeMode == ThemeMode.light
              ? Brightness.light
              : MediaQuery.platformBrightnessOf(context);

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: brightness == Brightness.light
                  ? Brightness.dark
                  : Brightness.light,
              statusBarBrightness: brightness == Brightness.light
                  ? Brightness.light
                  : Brightness.dark,
            ),
            child: MaterialApp(
              title: AppStrings.of(context).appName,
              debugShowCheckedModeBanner: false,
              locale: controller.locale,
              supportedLocales: AppLanguage.supportedLocales,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: controller.themeMode,
              builder: (context, child) {
                final mediaQuery = MediaQuery.of(context);
                final scale = mediaQuery.textScaler.scale(1.0);
                final clampedScale = scale.clamp(1.0, 1.1);
                return MediaQuery(
                  data: mediaQuery.copyWith(
                    textScaler: TextScaler.linear(clampedScale),
                  ),
                  child: child!,
                );
              },
              home: _buildHome(controller),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHome(AppController controller) {
    return switch (controller.authStatus) {
      AppAuthStatus.authenticated when controller.profileCheckInProgress =>
        const _AuthLoadingScreen(),
      AppAuthStatus.authenticated when controller.requiresRegistrationCompletion =>
        const EmailRegisterScreen(finalizeOnly: true),
      AppAuthStatus.authenticated when controller.requiresProfileSetup =>
        const FirstProfileSetupScreen(),
      AppAuthStatus.authenticated => const AppShell(),
      _ => const EmailOtpSignInScreen(),
    };
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      key: const ValueKey('auth-profile-loading-screen'),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(strings.profilePreparingLabel),
          ],
        ),
      ),
    );
  }
}
