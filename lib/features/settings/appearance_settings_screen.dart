import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import '../../app/app_theme.dart';
import '../../shared/widgets/page_visual_language.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: const ValueKey('appearance-settings-screen'),
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          strings.appearanceSettingsTitle,
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.languageTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: isDark ? AppTheme.warmWhite90 : null,
                      ),
                    ),
                    RadioGroup<AppLanguage>(
                      groupValue: controller.language,
                      onChanged: (value) {
                        if (value != null) {
                          controller.setLanguage(value);
                        }
                      },
                      child: Column(
                        children: [
                          for (final lang in AppLanguage.values)
                            RadioListTile<AppLanguage>(
                              title: Text(lang.displayName),
                              value: lang,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(indent: 20, endIndent: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.themeTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: isDark ? AppTheme.warmWhite90 : null,
                      ),
                    ),
                    RadioGroup<AppThemePreference>(
                      groupValue: controller.themePreference,
                      onChanged: (value) {
                        if (value != null) {
                          controller.setThemePreference(value);
                        }
                      },
                      child: Column(
                        children: [
                          RadioListTile<AppThemePreference>(
                            title: Text(strings.themeSystemLabel),
                            value: AppThemePreference.system,
                          ),
                          RadioListTile<AppThemePreference>(
                            title: Text(strings.themeLightLabel),
                            value: AppThemePreference.light,
                          ),
                          RadioListTile<AppThemePreference>(
                            title: Text(strings.themeDarkLabel),
                            value: AppThemePreference.dark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(indent: 20, endIndent: 20),
              ListTile(
                leading: Icon(
                  Icons.schedule_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: Text(strings.timeZoneTitle),
                subtitle: Text('${_timeZoneLabel()} · ${strings.timeZoneHint}'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _timeZoneLabel() {
    final offset = DateTime.now().timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final totalMinutes = offset.inMinutes.abs();
    final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
    final name = DateTime.now().timeZoneName;
    return '$name (UTC$sign$hours:$minutes)';
  }
}
