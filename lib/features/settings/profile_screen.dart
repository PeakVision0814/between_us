import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import '../../app/app_theme.dart';
import '../../shared/widgets/page_visual_language.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          strings.isChinese ? '个人资料' : 'My profile',
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
          variant: PageSurfaceVariant.secondary,
          radius: AppTheme.radius2xl,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _ProfileRow(
                label: strings.isChinese ? '昵称' : 'Display name',
                value: _resolvedSelfName(controller, strings),
                valueKey: const ValueKey('profile-display-name'),
                isDark: isDark,
              ),
              const PageDivider(indent: 20),
              _ProfileRow(
                label: strings.isChinese ? '邮箱' : 'Email',
                value: _emailLabel(strings, controller.email),
                valueKey: const ValueKey('profile-email'),
                isPlaceholder: controller.email == null,
                isDark: isDark,
              ),
              const PageDivider(indent: 20),
              _ProfileRow(
                label: strings.isChinese ? '性别' : 'Gender',
                value: _genderLabel(strings, controller.gender),
                valueKey: const ValueKey('profile-gender'),
                isDark: isDark,
              ),
              const PageDivider(indent: 20),
              _ProfileRow(
                label: strings.isChinese ? '生日' : 'Birthday',
                value: _birthdayLabel(strings, controller.birthday),
                valueKey: const ValueKey('profile-birthday'),
                isPlaceholder: controller.birthday == null,
                isDark: isDark,
                isLast: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _resolvedSelfName(AppController controller, AppStrings strings) {
    final normalized = _normalizeName(controller.displayName);
    return normalized ?? (strings.isChinese ? '我' : 'Me');
  }

  String? _normalizeName(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  String _emailLabel(AppStrings strings, String? email) {
    if (email == null || email.isEmpty) {
      return strings.isChinese ? '未获取' : 'Unavailable';
    }
    return email;
  }

  String _genderLabel(AppStrings strings, String? gender) {
    return switch (gender) {
      AppController.genderMale => strings.isChinese ? '男生' : 'Male',
      AppController.genderFemale => strings.isChinese ? '女生' : 'Female',
      _ => strings.isChinese ? '尚未补充' : 'Not set yet',
    };
  }

  String _birthdayLabel(AppStrings strings, DateTime? birthday) {
    if (birthday == null) {
      return strings.isChinese ? '还没有填写' : 'Not added yet.';
    }

    final month = birthday.month.toString().padLeft(2, '0');
    final day = birthday.day.toString().padLeft(2, '0');
    return strings.isChinese
        ? '${birthday.year} 年 $month 月 $day 日'
        : '${birthday.year}-$month-$day';
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    required this.value,
    this.valueKey,
    this.isPlaceholder = false,
    this.isDark = false,
    this.isLast = false,
  });

  final String label;
  final String value;
  final Key? valueKey;
  final bool isPlaceholder;
  final bool isDark;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 6, 20, isLast ? 14 : 6),
      child: PageListItem(
        compact: true,
        leading: SizedBox(
          width: 72,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppTheme.warmWhite60
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        title: value,
        titleKey: valueKey,
        titleStyle: theme.textTheme.bodyLarge,
        titleColor: isPlaceholder
            ? (isDark ? AppTheme.warmWhite25 : colorScheme.onSurfaceVariant)
            : null,
      ),
    );
  }
}
