import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import '../../app/app_theme.dart';
import '../../shared/widgets/page_visual_language.dart';
import 'account_security_routes.dart';
import 'appearance_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_settings_screen.dart';
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
          children: [
            PageSurfaceCard(
              key: const ValueKey('us-preferences-section'),
              child: Column(
                children: [
                  PageListItem(
                    key: const ValueKey('profile-entry-section'),
                    leading: Icon(
                      Icons.person_outline,
                      color: theme.colorScheme.primary,
                    ),
                    title: strings.viewProfileTitle,
                    subtitle: controller.displayName ??
                        (strings.isChinese ? '未设置' : 'Not set'),
                    trailing: _chevron(isDark, theme),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ProfileScreen(
                                controller: controller,
                                spaceStatusRouteBuilder:
                                    buildAccountSecuritySpaceStatusRoute,
                              ),
                        ),
                      );
                    },
                  ),
                  PageDivider(indent: 56),
                  PageListItem(
                    key: const ValueKey('appearance-entry'),
                    leading: Icon(
                      Icons.palette_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: strings.appearanceSettingsTitle,
                    subtitle: _appearanceSummary(controller, strings),
                    trailing: _chevron(isDark, theme),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AppearanceSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  PageDivider(indent: 56),
                  PageListItem(
                    key: const ValueKey('notification-entry'),
                    leading: Icon(
                      Icons.notifications_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: strings.notificationSettingsTitle,
                    subtitle: controller.notificationPreviewEnabled
                        ? strings.notificationPreviewEnabledLabel
                        : strings.notificationPreviewDisabledLabel,
                    trailing: _chevron(isDark, theme),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  PageDivider(indent: 56),
                  PageListItem(
                    key: const ValueKey('privacy-sharing-entry'),
                    leading: Icon(
                      Icons.shield_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: strings.privacySettingsTitle,
                    subtitle: controller.cycleSharingEnabled
                        ? strings.cycleSharingEnabledLabel
                        : strings.cycleSharingDisabledLabel,
                    trailing: _chevron(isDark, theme),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PrivacySettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PageSurfaceCard(
              key: const ValueKey('us-signout-section'),
              child: PageListItem(
                key: const ValueKey('sign-out-tile'),
                leading: Icon(
                  Icons.logout_rounded,
                  color: theme.colorScheme.error,
                ),
                title: strings.signOutTitle,
                titleColor: theme.colorScheme.error,
                trailing: controller.signOutInProgress
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _chevron(isDark, theme),
                enabled: !controller.signOutInProgress,
                onTap: () => _confirmSignOut(context, controller, strings),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _chevron(bool isDark, ThemeData theme) {
    return Icon(
      Icons.chevron_right,
      size: 20,
      color: isDark
          ? AppTheme.warmWhite25
          : theme.colorScheme.onSurfaceVariant,
    );
  }

  static String _appearanceSummary(
    AppController controller,
    AppStrings strings,
  ) {
    final lang = controller.language.displayName;
    final theme = switch (controller.themePreference) {
      AppThemePreference.system => strings.themeSystemLabel,
      AppThemePreference.light => strings.themeLightLabel,
      AppThemePreference.dark => strings.themeDarkLabel,
    };
    return '$lang · $theme';
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
}
