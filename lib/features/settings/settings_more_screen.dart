import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import '../../app/app_theme.dart';
import '../../shared/widgets/page_visual_language.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!controller.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }

    return Scaffold(
      key: const ValueKey('settings-more-screen'),
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          strings.settingsMoreTitle,
          style: TextStyle(color: isDark ? AppTheme.warmWhite90 : null),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: PageAtmosphere(
        padding: const EdgeInsets.fromLTRB(16, 92, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageSectionHeader(
              title: strings.isChinese ? '偏好设置' : 'Preferences',
              subtitle: strings.isChinese
                  ? '语言 · 主题 · 时区'
                  : 'Language · theme · timezone',
            ),
            const SizedBox(height: 10),
            buildPreferencesSection(context),
            const SizedBox(height: 24),
            PageSectionHeader(
              title: strings.isChinese ? '账户操作' : 'Account',
              subtitle: strings.isChinese ? '安全退出' : 'Sign-out action',
            ),
            const SizedBox(height: 10),
            buildSignOutSection(context),
          ],
        ),
      ),
    );
  }
}
