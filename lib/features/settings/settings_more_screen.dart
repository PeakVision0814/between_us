import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import '../../app/app_theme.dart';

class SettingsMoreScreen extends StatelessWidget {
  const SettingsMoreScreen({
    super.key,
    required this.buildPreferencesSection,
    required this.buildSignOutSection,
  });

  final WidgetBuilder buildPreferencesSection;
  final WidgetBuilder buildSignOutSection;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final strings = AppStrings.of(context);

    if (!controller.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: const ValueKey('settings-more-screen'),
      appBar: AppBar(
        title: Text(
          strings.settingsMoreTitle,
          style: TextStyle(
            color: isDark ? AppTheme.warmWhite90 : null,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          // ── Preferences section ──
          buildPreferencesSection(context),
          const SizedBox(height: 24),
          // ── Sign out section ──
          buildSignOutSection(context),
        ],
      ),
    );
  }
}
