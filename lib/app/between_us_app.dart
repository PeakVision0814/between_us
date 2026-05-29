import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_controller.dart';
import 'app_shell.dart';
import 'app_strings.dart';
import 'app_theme.dart';
import '../features/auth/email_otp_sign_in_screen.dart';
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
          return MaterialApp(
            title: AppStrings.of(context).appName,
            debugShowCheckedModeBanner: false,
            locale: controller.locale,
            supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: controller.themeMode,
            home: _buildHome(controller),
          );
        },
      ),
    );
  }

  Widget _buildHome(AppController controller) {
    return switch (controller.authStatus) {
      AppAuthStatus.authenticated when controller.profileCheckInProgress =>
        const _AuthLoadingScreen(),
      AppAuthStatus.authenticated when controller.requiresDisplayNameSetup =>
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
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              strings.isChinese ? '正在准备你的资料...' : 'Preparing your profile...',
            ),
          ],
        ),
      ),
    );
  }
}
