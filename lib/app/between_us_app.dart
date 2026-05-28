import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_controller.dart';
import 'app_shell.dart';
import 'app_strings.dart';
import 'app_theme.dart';

class BetweenUsApp extends StatefulWidget {
  const BetweenUsApp({super.key});

  @override
  State<BetweenUsApp> createState() => _BetweenUsAppState();
}

class _BetweenUsAppState extends State<BetweenUsApp> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController();
    _controller.loadPreferences();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return MaterialApp(
            title: AppStrings.of(context).appName,
            debugShowCheckedModeBanner: false,
            locale: _controller.locale,
            supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _controller.themeMode,
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
