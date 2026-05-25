import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'app_theme.dart';

class BetweenUsApp extends StatelessWidget {
  const BetweenUsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Between Us',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppShell(),
    );
  }
}
