import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/section_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.settingsTitle)),
      body: SafeArea(
        child: AppPage(
          children: [
            SectionHeader(title: strings.settingsLanguageTitle),
            _SettingsCard(
              child: RadioGroup<AppLanguage>(
                groupValue: controller.language,
                onChanged: (value) {
                  if (value != null) {
                    controller.setLanguage(value);
                  }
                },
                child: Column(
                  children: [
                    RadioListTile<AppLanguage>(
                      title: Text(strings.chineseLabel),
                      value: AppLanguage.zhCn,
                    ),
                    const Divider(height: 1),
                    RadioListTile<AppLanguage>(
                      title: Text(strings.englishLabel),
                      value: AppLanguage.en,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            SectionHeader(title: strings.settingsThemeTitle),
            _SettingsCard(
              child: RadioGroup<AppThemePreference>(
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
                    const Divider(height: 1),
                    RadioListTile<AppThemePreference>(
                      title: Text(strings.themeLightLabel),
                      value: AppThemePreference.light,
                    ),
                    const Divider(height: 1),
                    RadioListTile<AppThemePreference>(
                      title: Text(strings.themeDarkLabel),
                      value: AppThemePreference.dark,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            SectionHeader(title: strings.settingsTimeZoneTitle),
            _SettingsCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.schedule_outlined),
                    title: Text(_timeZoneLabel()),
                    subtitle: Text(strings.settingsTimeZoneHint),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SectionHeader(title: strings.settingsLockPreviewTitle),
            _SettingsCard(
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    value: controller.lockScreenPreviewEnabled,
                    onChanged: controller.setLockScreenPreviewEnabled,
                    title: Text(strings.settingsLockPreviewTitle),
                    subtitle: Text(strings.settingsLockPreviewSubtitle),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              strings.settingsLocalHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _timeZoneLabel() {
    final offset = DateTime.now().timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final totalMinutes = offset.inMinutes.abs();
    final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
    final name = DateTime.now().timeZoneName;
    return '$name (UTC$sign$hours:$minutes)';
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(child: child);
  }
}
