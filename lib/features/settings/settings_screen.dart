import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/section_header.dart';

class UsScreen extends StatelessWidget {
  const UsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final strings = AppStrings.of(context);

    return AppPage(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.usLeadTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(strings.usLeadSubtitle),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HeroFact(
                        title: strings.spaceNameTitle,
                        value: strings.spaceNameValue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HeroFact(
                        title: strings.spaceStatusLabel,
                        value: strings.spaceStatusValue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader(title: strings.preferencesSection),
        _PanelCard(
          child: Column(
            children: [
              _InfoRow(
                title: strings.languageTitle,
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
                      RadioListTile<AppLanguage>(
                        title: Text(strings.englishLabel),
                        value: AppLanguage.en,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              _InfoRow(
                title: strings.themeTitle,
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
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: Text(strings.timeZoneTitle),
                subtitle: Text('${_timeZoneLabel()} · ${strings.timeZoneHint}'),
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                value: controller.notificationPreviewEnabled,
                onChanged: controller.setNotificationPreviewEnabled,
                title: Text(strings.notificationPreviewTitle),
                subtitle: Text(strings.notificationPreviewSubtitle),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader(title: strings.spaceSection),
        _PanelCard(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.home_work_outlined),
                title: Text(strings.spaceNameTitle),
                subtitle: Text(strings.spaceNameValue),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: Text(strings.inviteStatusTitle),
                subtitle: Text(strings.inviteStatusValue),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.rule_folder_outlined),
                title: Text(strings.sharedRulesTitle),
                subtitle: Text(strings.sharedRulesValue),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.favorite_outline),
                title: Text(strings.relationshipDateTitle),
                subtitle: Text(strings.relationshipDateValue),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader(title: strings.privacySection),
        _PanelCard(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: Text(strings.cyclePrivacyTitle),
                subtitle: Text(strings.cyclePrivacyValue),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.link_off_outlined),
                title: Text(strings.exportUnlinkTitle),
                subtitle: Text(strings.exportUnlinkValue),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          strings.localPrototypeHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
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

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(child: child);
  }
}

class _HeroFact extends StatelessWidget {
  const _HeroFact({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
