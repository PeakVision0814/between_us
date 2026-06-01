import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import '../../shared/widgets/app_page.dart';

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

    return Scaffold(
      key: const ValueKey('settings-more-screen'),
      appBar: AppBar(title: Text(strings.settingsMoreTitle)),
      body: SafeArea(
        child: AppPage(
          children: [
            buildPreferencesSection(context),
            const SizedBox(height: 20),
            buildSignOutSection(context),
          ],
        ),
      ),
    );
  }
}
