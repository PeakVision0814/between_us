import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import '../../app/app_theme.dart';
import '../../shared/widgets/page_visual_language.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: const ValueKey('privacy-settings-screen'),
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          strings.privacySettingsTitle,
          style: TextStyle(color: isDark ? AppTheme.warmWhite90 : null),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: PageAtmosphere(
        padding: const EdgeInsets.fromLTRB(16, 92, 16, 32),
        child: PageSurfaceCard(
          child: controller.gender == AppController.genderFemale
              ? SwitchListTile.adaptive(
                  key: const ValueKey('cycle-sharing-switch'),
                  value: controller.cycleSharingEnabled,
                  onChanged: (enabled) async {
                    final success = await controller.setCycleSharingEnabled(
                      enabled,
                    );
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(strings.cycleCreateFailedError)),
                      );
                    }
                  },
                  title: Text(strings.cycleSharingTitle),
                  subtitle: Text(strings.cycleSharingSubtitle),
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    strings.privacySettingsHiddenForMale,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppTheme.warmWhite60
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
