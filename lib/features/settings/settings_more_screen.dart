import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import '../../app/app_theme.dart';
import '../../shared/widgets/page_visual_language.dart';
import 'profile_screen.dart';

class SettingsMoreScreen extends StatelessWidget {
  const SettingsMoreScreen({super.key});

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
              title: strings.isChinese ? '个人资料' : 'Profile',
              subtitle: strings.isChinese
                  ? '昵称 · 邮箱 · 性别 · 生日'
                  : 'Name · email · gender · birthday',
            ),
            const SizedBox(height: 10),
            Card(
              key: const ValueKey('profile-entry-section'),
              child: ListTile(
                leading: Icon(
                  Icons.person_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(strings.isChinese ? '查看个人资料' : 'View profile'),
                subtitle: Text(
                  strings.isChinese
                      ? '昵称、邮箱、性别、生日'
                      : 'Display name, email, gender, birthday',
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: isDark
                      ? AppTheme.warmWhite25
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProfileScreen(controller: controller),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            PageSectionHeader(
              title: strings.isChinese ? '偏好设置' : 'Preferences',
              subtitle: strings.isChinese
                  ? '语言 · 主题 · 时区'
                  : 'Language · theme · timezone',
            ),
            const SizedBox(height: 10),
            _buildPreferencesSection(
              context,
              strings,
              controller,
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            PageSectionHeader(
              title: strings.isChinese ? '账户操作' : 'Account',
              subtitle: strings.isChinese ? '安全退出' : 'Sign-out action',
            ),
            const SizedBox(height: 10),
            _buildSignOutSection(context, strings, controller, isDark: isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection(
    BuildContext context,
    AppStrings strings,
    AppController controller, {
    required bool isDark,
  }) {
    return Card(
      key: const ValueKey('us-preferences-section'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.languageTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(strings.timeZoneTitle),
            subtitle: Text('${_timeZoneLabel()} · ${strings.timeZoneHint}'),
          ),
          const Divider(indent: 20, endIndent: 20),
          SwitchListTile.adaptive(
            value: controller.notificationPreviewEnabled,
            onChanged: controller.setNotificationPreviewEnabled,
            title: Text(strings.notificationPreviewTitle),
            subtitle: Text(strings.notificationPreviewSubtitle),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutSection(
    BuildContext context,
    AppStrings strings,
    AppController controller, {
    required bool isDark,
  }) {
    return Card(
      key: const ValueKey('us-signout-section'),
      child: ListTile(
        key: const ValueKey('sign-out-tile'),
        leading: Icon(
          Icons.logout_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(
          strings.isChinese ? '退出登录' : 'Sign out',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        subtitle: Text(
          strings.isChinese
              ? '安全退出当前账号，并回到邮箱验证码登录页。'
              : 'Sign out of this account and return to the email OTP login screen.',
        ),
        trailing: controller.signOutInProgress
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.chevron_right,
                size: 20,
                color: isDark
                    ? AppTheme.warmWhite25
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        enabled: !controller.signOutInProgress,
        onTap: () => _confirmSignOut(context, controller, strings),
      ),
    );
  }

  Future<void> _confirmSignOut(
    BuildContext context,
    AppController controller,
    AppStrings strings,
  ) async {
    if (controller.signOutInProgress) return;

    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          strings.isChinese ? '确认退出登录？' : 'Sign out of this account?',
        ),
        content: Text(
          strings.isChinese
              ? '退出后会清理当前账号的本地登录状态、昵称和偏好，并回到登录页。'
              : 'This will clear the current account session, nickname, and local preferences, then return to the login screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.isChinese ? '取消' : 'Cancel'),
          ),
          FilledButton(
            key: const ValueKey('sign-out-confirm-button'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.isChinese ? '退出登录' : 'Sign out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true && context.mounted) {
      final success = await controller.signOut();
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.isChinese
                  ? '退出登录失败，请稍后重试。'
                  : 'Failed to sign out. Please try again later.',
            ),
          ),
        );
      }
    }
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
