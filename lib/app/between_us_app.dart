import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_controller.dart';
import 'app_shell.dart';
import 'app_strings.dart';
import 'app_theme.dart';

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
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
