import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import '../../app/app_theme.dart';
import '../../shared/widgets/page_visual_language.dart';
import 'settings_more_screen.dart';

class UsScreen extends StatefulWidget {
  const UsScreen({super.key});

  @override
  State<UsScreen> createState() => _UsScreenState();
}

class _UsScreenState extends State<UsScreen> with WidgetsBindingObserver {
  String? _spaceName;
  String? _relationshipStartDate;
  String? _coupleSpaceId;
  int _memberCount = 0;
  bool _loadingSpaceData = false;

  String? _currentInviteCode;
  DateTime? _currentInviteExpiresAt;
  bool _generatingInvite = false;
  Timer? _spaceRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSpaceData();
    _spaceRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadSpaceData(),
    );
  }

  @override
  void dispose() {
    _spaceRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSpaceData();
    }
  }

  Future<void> _loadSpaceData() async {
    if (_loadingSpaceData) return;
    _loadingSpaceData = true;
    final appController = AppScope.read(context);
    if (!appController.supabaseReady) {
      debugPrint(
        '[Space] skip load: supabase not ready (${appController.supabaseFailureReason ?? 'unknown'})',
      );
      if (mounted) {
        setState(() {});
      }
      _loadingSpaceData = false;
      return;
    }

    try {
      _coupleSpaceId = appController.currentSpaceId;
      if (_coupleSpaceId == null) {
        if (mounted) {
          setState(() {});
        }
        return;
      }

      final spaceResponse = await Supabase.instance.client
          .from('couple_spaces')
          .select('id, space_name, relationship_start_date')
          .eq('id', _coupleSpaceId!)
          .maybeSingle();

      debugPrint('[Space] loaded: $spaceResponse');

      if (spaceResponse != null) {
        _coupleSpaceId = spaceResponse['id'] as String;
        _spaceName = spaceResponse['space_name'] as String?;
        _relationshipStartDate =
            spaceResponse['relationship_start_date'] as String?;

        final membersResponse = await Supabase.instance.client
            .from('couple_memberships')
            .select('id')
            .eq('couple_space_id', _coupleSpaceId!)
            .eq('status', 'active');

        _memberCount = (membersResponse as List).length;
        debugPrint('[Space] id=$_coupleSpaceId members=$_memberCount');
      }
    } catch (e) {
      debugPrint('[Space] load failed: $e');
    } finally {
      _loadingSpaceData = false;
    }

    if (mounted) {
      setState(() {});
    }
  }

  String _generateRandomCode() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _generateInviteCode() async {
    if (_generatingInvite) return;

    final coupleSpaceId = AppScope.read(context).currentSpaceId;
    if (coupleSpaceId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请检查网络连接')));
      return;
    }

    setState(() => _generatingInvite = true);

    try {
      final code = _generateRandomCode();
      final response = await Supabase.instance.client.rpc(
        'create_couple_invite',
        params: {'p_couple_space_id': coupleSpaceId, 'p_plain_code': code},
      );

      final data = switch (response) {
        final List<dynamic> rows when rows.isNotEmpty =>
          rows.first as Map<String, dynamic>,
        final Map<String, dynamic> row => row,
        _ => throw StateError('Unexpected invite response: $response'),
      };
      setState(() {
        _currentInviteCode = code;
        _currentInviteExpiresAt = DateTime.parse(data['expires_at'] as String);
      });
    } catch (e) {
      debugPrint('[Invite] generate failed: $e');
      if (mounted) {
        final strings = AppStrings.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.isChinese
                  ? '邀请码生成失败，请稍后重试'
                  : 'Failed to generate invite code. Please try again later.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _generatingInvite = false);
      }
    }
  }

  Future<void> _acceptInvite(String code) async {
    try {
      await Supabase.instance.client.rpc(
        'accept_couple_invite',
        params: {'p_plain_code': code},
      );

      await _loadSpaceData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.of(context).isChinese
                  ? '已成功加入空间'
                  : 'Successfully joined the space',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[Invite] accept failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.of(context).isChinese
                  ? '邀请码无效或已过期'
                  : 'Invalid or expired invite code',
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmSignOut() async {
    final controller = AppScope.read(context);
    if (controller.signOutInProgress) {
      return;
    }

    final strings = AppStrings.of(context);
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

    if (shouldSignOut == true) {
      await _handleSignOut();
    }
  }

  Future<void> _handleSignOut() async {
    final controller = AppScope.read(context);
    final success = await controller.signOut();
    if (!mounted || success) {
      return;
    }

    final strings = AppStrings.of(context);
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

  Future<void> _openSettingsMore() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsMoreScreen(
          buildPreferencesSection: (context) => _buildPreferencesSection(
            context,
            AppStrings.of(context),
            AppScope.of(context),
          ),
          buildSignOutSection: (context) => _buildSignOutSection(
            context,
            AppStrings.of(context),
            AppScope.of(context),
          ),
        ),
      ),
    );
  }

  void _openProfileScreen(AppController controller, AppStrings strings) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ProfileScreen(controller: controller),
      ),
    );
  }

  void _openPartnerScreen(
    AppController controller,
    AppStrings strings, {
    required bool isPaired,
    required String? partnerName,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PartnerScreen(
          controller: controller,
          isPaired: isPaired,
          partnerName: partnerName,
          currentInviteCode: _currentInviteCode,
          currentInviteExpiresAt: _currentInviteExpiresAt,
          generatingInvite: _generatingInvite,
          onGenerateInvite: _generateInviteCode,
          onShowInviteDialog: _showInviteCodeDialog,
        ),
      ),
    );
  }

  void _showEditSpaceNameDialog() {
    final strings = AppStrings.of(context);
    final controller = TextEditingController(text: _spaceName ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.isChinese ? '修改空间名称' : 'Edit space name'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: strings.isChinese ? '输入新的空间名称' : 'Enter a new space name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.isChinese ? '取消' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(context);
              await _updateSpaceName(newName);
            },
            child: Text(strings.isChinese ? '保存' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSpaceName(String newName) async {
    if (_coupleSpaceId == null) return;
    try {
      await Supabase.instance.client
          .from('couple_spaces')
          .update({'space_name': newName})
          .eq('id', _coupleSpaceId!);
      setState(() => _spaceName = newName);
    } catch (_) {
      if (mounted) {
        final strings = AppStrings.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.isChinese
                  ? '修改失败，请重试'
                  : 'Failed to update, please try again',
            ),
          ),
        );
      }
    }
  }

  void _showInviteCodeDialog() {
    final strings = AppStrings.of(context);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.isChinese ? '输入邀请码' : 'Enter invite code'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: strings.isChinese
                ? '请输入对方分享的邀请码'
                : 'Enter the invite code shared by your partner',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.isChinese ? '取消' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptInvite(controller.text.trim());
            },
            child: Text(strings.isChinese ? '加入' : 'Join'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final effectiveMemberCount = max(_memberCount, controller.memberCount);
    final selfName = _resolvedSelfName(controller, strings);
    final partnerName = _resolvedPartnerName(controller);
    final isPaired = effectiveMemberCount >= 2 && partnerName != null;
    final isDark = theme.brightness == Brightness.dark;

    return PageAtmosphere(
      padding: EdgeInsets.fromLTRB(16, isDark ? 8 : 4, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRelationshipHero(
            context,
            strings,
            controller: controller,
            selfName: selfName,
            partnerName: partnerName,
            isPaired: isPaired,
            isDark: isDark,
            selfGender: controller.gender,
          ),
          const SizedBox(height: 24),
          PageSectionHeader(
            title: strings.spaceSection,
            subtitle: strings.isChinese ? '共享空间' : 'Shared space',
          ),
          const SizedBox(height: 10),
          _buildSpaceSection(
            context,
            strings,
            isPaired: isPaired,
            isDark: isDark,
          ),
          const SizedBox(height: 24),
          PageSectionHeader(
            title: strings.settingsMoreTitle,
            subtitle: strings.isChinese ? '偏好与账户' : 'Preferences and account',
          ),
          const SizedBox(height: 10),
          _buildSettingsEntrySection(context, strings, isDark: isDark),
        ],
      ),
    );
  }

  // ─── Relationship Hero ──────────────────────────────────────────────

  Widget _buildRelationshipHero(
    BuildContext context,
    AppStrings strings, {
    required AppController controller,
    required String selfName,
    required String? partnerName,
    required bool isPaired,
    required bool isDark,
    required String? selfGender,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final spaceName = _normalizeName(_spaceName) ?? strings.spaceNameValue;
    final selfGenderIcon = _genderIcon(selfGender);
    final partnerLabel = partnerName ?? (strings.isChinese ? 'TA' : 'Partner');

    return Container(
      key: const ValueKey('us-hero-section'),
      decoration: BoxDecoration(
        gradient: isDark
            ? AppTheme.heroGradientDark
            : AppTheme.heroGradientLight,
        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
        boxShadow: isDark ? AppTheme.shadowHeroDark : AppTheme.shadowHeroLight,
        border: Border.all(
          color: isDark
              ? AppTheme.heroGlowBlush.withValues(alpha: 0.26)
              : Colors.white.withValues(alpha: 0.72),
          width: 0.9,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? AppTheme.heroAtmosphereDark
                      : AppTheme.heroAtmosphereLight,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  onTap: () => _openProfileScreen(controller, strings),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.55),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      size: 20,
                      color: isDark
                          ? AppTheme.warmWhite60
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spaceName,
                    key: const ValueKey('us-hero-space-name'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isDark
                          ? AppTheme.warmWhite90
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 174,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _HeroAvatarPair(
                              selfAvatarLabel: _avatarLabel(
                                selfName,
                                fallback: strings.isChinese ? '我' : 'M',
                              ),
                              partnerAvatarLabel: _avatarLabel(
                                partnerName,
                                fallback: strings.isChinese ? 'TA' : 'P',
                              ),
                              isPaired: isPaired,
                              isDark: isDark,
                              onTapPartner: () => _openPartnerScreen(
                                controller,
                                strings,
                                isPaired: isPaired,
                                partnerName: partnerName,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: _HeroNameLabel(
                                    name: selfName,
                                    genderIcon: selfGenderIcon,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _HeroNameLabel(
                                    name: isPaired ? partnerLabel : '—',
                                    genderIcon: null,
                                    isPlaceholder: !isPaired,
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Space Section ──────────────────────────────────────────────────

  Widget _buildSpaceSection(
    BuildContext context,
    AppStrings strings, {
    required bool isPaired,
    required bool isDark,
  }) {
    return _UsCard(
      isDark: isDark,
      variant: PageSurfaceVariant.primary,
      key: const ValueKey('us-space-section'),
      child: Column(
        children: [
          _SpaceListTile(
            icon: Icons.home_work_outlined,
            title: strings.spaceNameTitle,
            subtitle: _spaceName ?? strings.spaceNameValue,
            trailing: Icon(
              Icons.edit_outlined,
              size: 20,
              color: isDark
                  ? AppTheme.warmWhite25
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onTap: _showEditSpaceNameDialog,
            isDark: isDark,
          ),
          _UsDivider(isDark: isDark),
          _SpaceListTile(
            icon: Icons.favorite_outline,
            title: strings.spaceStatusLabel,
            subtitle: _relationshipStatusLabel(strings, isPaired: isPaired),
            isDark: isDark,
          ),
          _UsDivider(isDark: isDark),
          _SpaceListTile(
            icon: Icons.mail_outline,
            title: strings.inviteStatusTitle,
            subtitle: _inviteSummaryText(strings, isPaired: isPaired),
            isDark: isDark,
          ),
          if (_currentInviteCode != null &&
              _currentInviteExpiresAt != null) ...[
            _UsDivider(isDark: isDark),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: _InviteCodeBox(
                code: _currentInviteCode!,
                expiryText: _inviteExpiryText(
                  strings,
                  _currentInviteExpiresAt!,
                ),
                isDark: isDark,
                showCopy: true,
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: _currentInviteCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(strings.isChinese ? '已复制' : 'Copied'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ],
          if (!isPaired) ...[
            _UsDivider(isDark: isDark),
            Padding(
              key: const ValueKey('us-space-invite-actions'),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _generatingInvite ? null : _generateInviteCode,
                      icon: _generatingInvite
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.vpn_key_outlined),
                      label: Text(
                        strings.isChinese ? '生成邀请码' : 'Generate invite code',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showInviteCodeDialog,
                      icon: const Icon(Icons.login),
                      label: Text(
                        strings.isChinese
                            ? '输入邀请码加入'
                            : 'Enter invite code to join',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          _UsDivider(isDark: isDark),
          _SpaceListTile(
            icon: Icons.event_outlined,
            title: strings.relationshipDateTitle,
            subtitle: _relationshipDateValue(strings),
            isDark: isDark,
            isLast: true,
          ),
        ],
      ),
    );
  }

  // ─── Settings Entry ─────────────────────────────────────────────────

  Widget _buildSettingsEntrySection(
    BuildContext context,
    AppStrings strings, {
    required bool isDark,
  }) {
    return _UsCard(
      isDark: isDark,
      variant: PageSurfaceVariant.tertiary,
      key: const ValueKey('us-settings-entry-section'),
      child: _SpaceListTile(
        key: const ValueKey('open-settings-more-tile'),
        icon: Icons.tune_rounded,
        title: strings.settingsMoreTitle,
        subtitle: strings.settingsMoreSubtitle,
        trailing: Icon(
          Icons.chevron_right,
          size: 20,
          color: isDark
              ? AppTheme.warmWhite25
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: _openSettingsMore,
        isDark: isDark,
        isLast: true,
      ),
    );
  }

  // ─── Preferences Section (for SettingsMoreScreen) ───────────────────

  Widget _buildPreferencesSection(
    BuildContext context,
    AppStrings strings,
    AppController controller,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _UsCard(
      isDark: isDark,
      variant: PageSurfaceVariant.primary,
      key: const ValueKey('us-preferences-section'),
      child: Column(
        children: [
          _PreferenceGroup(
            title: strings.languageTitle,
            isDark: isDark,
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
          _UsDivider(isDark: isDark),
          _PreferenceGroup(
            title: strings.themeTitle,
            isDark: isDark,
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
          _UsDivider(isDark: isDark),
          _SpaceListTile(
            icon: Icons.schedule_outlined,
            title: strings.timeZoneTitle,
            subtitle: '${_timeZoneLabel()} · ${strings.timeZoneHint}',
            isDark: isDark,
          ),
          _UsDivider(isDark: isDark),
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

  // ─── Sign Out Section (for SettingsMoreScreen) ──────────────────────

  Widget _buildSignOutSection(
    BuildContext context,
    AppStrings strings,
    AppController controller,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _UsCard(
      isDark: isDark,
      variant: PageSurfaceVariant.tertiary,
      key: const ValueKey('us-signout-section'),
      child: _SpaceListTile(
        key: const ValueKey('sign-out-tile'),
        icon: Icons.logout_rounded,
        iconColor: Theme.of(context).colorScheme.error,
        title: strings.isChinese ? '退出登录' : 'Sign out',
        titleColor: Theme.of(context).colorScheme.error,
        subtitle: strings.isChinese
            ? '安全退出当前账号，并回到邮箱验证码登录页。'
            : 'Sign out of this account and return to the email OTP login screen.',
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
        onTap: _confirmSignOut,
        isDark: isDark,
        isLast: true,
      ),
    );
  }

  // ─── Helper methods ─────────────────────────────────────────────────

  String _resolvedSelfName(AppController controller, AppStrings strings) {
    final normalized = _normalizeName(controller.displayName);
    return normalized ?? (strings.isChinese ? '我' : 'Me');
  }

  String? _resolvedPartnerName(AppController controller) {
    return _normalizeName(controller.partnerDisplayName);
  }

  String? _normalizeName(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  String _avatarLabel(String? name, {required String fallback}) {
    final normalized = _normalizeName(name);
    if (normalized == null) {
      return fallback.characters.first;
    }
    return normalized.characters.first;
  }

  IconData? _genderIcon(String? gender) {
    return switch (gender) {
      AppController.genderMale => Icons.male,
      AppController.genderFemale => Icons.female,
      _ => null,
    };
  }

  String _relationshipStatusLabel(
    AppStrings strings, {
    required bool isPaired,
  }) {
    if (!isPaired) {
      return strings.isChinese ? '等待另一半加入' : 'Waiting for partner';
    }

    final relationshipDays = _relationshipDays();
    if (relationshipDays != null) {
      return strings.isChinese
          ? '在一起第 $relationshipDays 天'
          : 'Day $relationshipDays together';
    }

    return strings.isChinese ? '已配对' : 'Paired';
  }

  String _inviteSummaryText(AppStrings strings, {required bool isPaired}) {
    if (isPaired) {
      return strings.isChinese
          ? '空间已进入双人状态，目前不需要新的邀请。'
          : 'This space is already paired, so no new invite is needed right now.';
    }

    if (_currentInviteCode != null && _currentInviteExpiresAt != null) {
      return strings.isChinese
          ? '邀请码已生成，等待对方输入后加入。'
          : 'An invite code is ready and waiting for your partner to use.';
    }

    return strings.isChinese
        ? '还在单人模式，可以继续生成邀请码或输入对方的邀请码。'
        : 'You are still in solo mode. You can generate an invite code or join with one here.';
  }

  String _relationshipDateValue(AppStrings strings) {
    if (_relationshipStartDate == null) {
      return strings.isChinese
          ? '还没有设置关系起点'
          : 'Relationship date has not been set yet';
    }

    final parsed = DateTime.tryParse(_relationshipStartDate!);
    if (parsed == null) {
      return _relationshipStartDate!;
    }

    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return strings.isChinese
        ? '${parsed.year} 年 $month 月 $day 日'
        : '${parsed.year}-$month-$day';
  }

  String _inviteExpiryText(AppStrings strings, DateTime expiresAt) {
    return strings.isChinese
        ? '有效期至 ${expiresAt.month} 月 ${expiresAt.day} 日 ${expiresAt.hour}:${expiresAt.minute.toString().padLeft(2, '0')}'
        : 'Expires ${expiresAt.month}/${expiresAt.day} ${expiresAt.hour}:${expiresAt.minute.toString().padLeft(2, '0')}';
  }

  int? _relationshipDays() {
    if (_relationshipStartDate == null) {
      return null;
    }

    final parsed = DateTime.tryParse(_relationshipStartDate!);
    if (parsed == null) {
      return null;
    }

    final start = DateUtils.dateOnly(parsed);
    final today = DateUtils.dateOnly(DateTime.now());
    if (start.isAfter(today)) {
      return null;
    }
    return today.difference(start).inDays + 1;
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

// ═══════════════════════════════════════════════════════════════════════
// Profile Screen (secondary page)
// ═══════════════════════════════════════════════════════════════════════

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen({required this.controller});

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageSectionHeader(
              title: strings.isChinese ? '关于我' : 'About me',
              subtitle: strings.isChinese ? '基本资料' : 'Basic info',
            ),
            const SizedBox(height: 10),
            _UsCard(
              isDark: isDark,
              variant: PageSurfaceVariant.secondary,
              child: Column(
                children: [
                  _ProfileRow(
                    label: strings.isChinese ? '昵称' : 'Display name',
                    value: _resolvedSelfName(controller, strings),
                    valueKey: const ValueKey('profile-display-name'),
                    isDark: isDark,
                  ),
                  _UsDivider(isDark: isDark),
                  _ProfileRow(
                    label: strings.isChinese ? '性别' : 'Gender',
                    value: _genderLabel(strings, controller.gender),
                    valueKey: const ValueKey('profile-gender'),
                    isDark: isDark,
                  ),
                  _UsDivider(isDark: isDark),
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
          ],
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

// ═══════════════════════════════════════════════════════════════════════
// Partner Screen (secondary page)
// ═══════════════════════════════════════════════════════════════════════

class _PartnerScreen extends StatelessWidget {
  const _PartnerScreen({
    required this.controller,
    required this.isPaired,
    required this.partnerName,
    required this.currentInviteCode,
    required this.currentInviteExpiresAt,
    required this.generatingInvite,
    required this.onGenerateInvite,
    required this.onShowInviteDialog,
  });

  final AppController controller;
  final bool isPaired;
  final String? partnerName;
  final String? currentInviteCode;
  final DateTime? currentInviteExpiresAt;
  final bool generatingInvite;
  final VoidCallback onGenerateInvite;
  final VoidCallback onShowInviteDialog;

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
          strings.isChinese ? 'TA 的资料' : 'Partner profile',
          style: TextStyle(color: isDark ? AppTheme.warmWhite90 : null),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: PageAtmosphere(
        padding: const EdgeInsets.fromLTRB(16, 92, 16, 32),
        child: isPaired
            ? _buildPairedContent(context, strings, isDark)
            : _buildSingleContent(context, strings, isDark),
      ),
    );
  }

  Widget _buildPairedContent(
    BuildContext context,
    AppStrings strings,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = partnerName ?? (strings.isChinese ? 'TA' : 'Partner');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageSectionHeader(
          title: strings.isChinese ? '关于 TA' : 'About partner',
          subtitle: strings.isChinese ? '已加入空间' : 'Joined the space',
        ),
        const SizedBox(height: 10),
        _UsCard(
          isDark: isDark,
          variant: PageSurfaceVariant.secondary,
          key: const ValueKey('us-partner-profile-section'),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SoftAvatar(
                    label: name.characters.first,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          key: const ValueKey('us-partner-name'),
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          strings.isChinese
                              ? '已加入空间'
                              : 'Has joined the space',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppTheme.warmWhite60
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PageInsetPanel(
                child: Text(
                  strings.isChinese
                      ? '关于 TA 的更多资料，会出现在这里。'
                      : 'More about your partner will appear here.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppTheme.warmWhite60
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSingleContent(
    BuildContext context,
    AppStrings strings,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageSectionHeader(
          title: strings.isChinese ? '邀请 TA' : 'Invite your partner',
          subtitle: strings.isChinese
              ? '先给 TA 留一个位置'
              : 'Leave a spot for your partner',
        ),
        const SizedBox(height: 10),
        _UsCard(
          isDark: isDark,
          variant: PageSurfaceVariant.secondary,
          key: const ValueKey('us-invite-placeholder-section'),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PageIconBadge(
                    icon: Icons.mark_email_unread_outlined,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      strings.isChinese
                          ? '先给 TA 留一个位置'
                          : 'Leave a spot for your partner',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                strings.isChinese
                    ? '等 TA 加入后，这里会慢慢变成只属于你们两个人的空间。'
                    : 'Once your partner joins, this space will start to feel like it belongs to the two of you.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppTheme.warmWhite60
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              if (currentInviteCode != null &&
                  currentInviteExpiresAt != null) ...[
                const SizedBox(height: 16),
                _InviteCodeBox(
                  code: currentInviteCode!,
                  expiryText: _inviteExpiryText(strings, currentInviteExpiresAt!),
                  isDark: isDark,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        PageSectionHeader(
          title: strings.isChinese ? '邀请操作' : 'Invite actions',
          subtitle: strings.isChinese
              ? '生成或输入邀请码'
              : 'Generate or enter an invite code',
        ),
        const SizedBox(height: 10),
        _UsCard(
          isDark: isDark,
          variant: PageSurfaceVariant.primary,
          key: const ValueKey('us-space-invite-actions'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: generatingInvite ? null : onGenerateInvite,
                    icon: generatingInvite
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.vpn_key_outlined),
                    label: Text(
                      strings.isChinese ? '生成邀请码' : 'Generate invite code',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onShowInviteDialog,
                    icon: const Icon(Icons.login),
                    label: Text(
                      strings.isChinese
                          ? '输入邀请码加入'
                          : 'Enter invite code to join',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _inviteExpiryText(AppStrings strings, DateTime expiresAt) {
    return strings.isChinese
        ? '有效期至 ${expiresAt.month} 月 ${expiresAt.day} 日 ${expiresAt.hour}:${expiresAt.minute.toString().padLeft(2, '0')}'
        : 'Expires ${expiresAt.month}/${expiresAt.day} ${expiresAt.hour}:${expiresAt.minute.toString().padLeft(2, '0')}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Private visual components
// ═══════════════════════════════════════════════════════════════════════

/// Unified card for the Us page — clean borders, soft elevation.
class _UsCard extends StatelessWidget {
  const _UsCard({
    super.key,
    required this.child,
    this.isDark = false,
    this.variant = PageSurfaceVariant.primary,
    this.padding,
  });

  final Widget child;
  final bool isDark;
  final PageSurfaceVariant variant;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return PageSurfaceCard(
      variant: variant,
      radius: AppTheme.radius2xl,
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );
  }
}

/// Divider between card rows — thin and warm.
class _UsDivider extends StatelessWidget {
  const _UsDivider({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return const PageDivider(indent: 20);
  }
}

/// Profile row for "My Profile" section.
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

/// List tile used in Space section and Settings entry.
class _SpaceListTile extends StatelessWidget {
  const _SpaceListTile({
    super.key,
    required this.title,
    required this.isDark,
    this.icon,
    this.iconColor,
    this.subtitle,
    this.trailing,
    this.titleColor,
    this.onTap,
    this.enabled = true,
    this.isLast = false,
  });

  final IconData? icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isDark;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveIconColor = iconColor ?? colorScheme.primary;

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 2, 18, isLast ? 10 : 2),
      child: PageListItem(
        onTap: enabled ? onTap : null,
        title: title,
        titleColor: titleColor,
        subtitle: subtitle,
        trailing: trailing,
        leading: icon == null
            ? null
            : PageIconBadge(icon: icon!, color: effectiveIconColor, size: 38),
      ),
    );
  }
}

/// Small icon container used in cards.
/// Soft avatar circle for partner profile.
class _SoftAvatar extends StatelessWidget {
  const _SoftAvatar({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.25),
                  AppTheme.heroGlowPurple.withValues(alpha: 0.15),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.12),
                  colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                ],
              ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeroAvatarPair extends StatelessWidget {
  const _HeroAvatarPair({
    required this.selfAvatarLabel,
    required this.partnerAvatarLabel,
    required this.isPaired,
    required this.isDark,
    required this.onTapPartner,
  });

  final String selfAvatarLabel;
  final String partnerAvatarLabel;
  final bool isPaired;
  final bool isDark;
  final VoidCallback onTapPartner;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final heartColor = isDark ? AppTheme.heroGlowBlush : colorScheme.primary;

    return SizedBox(
      width: 170,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 18,
            child: _HeroRelationshipAvatar(
              key: const ValueKey('us-hero-self-slot'),
              label: selfAvatarLabel,
              isDark: isDark,
            ),
          ),
          Positioned(
            right: 18,
            child: GestureDetector(
              onTap: onTapPartner,
              child: isPaired
                  ? _HeroRelationshipAvatar(
                      key: const ValueKey('us-hero-partner-slot'),
                      label: partnerAvatarLabel,
                      isDark: isDark,
                      alignRight: true,
                    )
                  : _HeroAddAvatar(
                      key: const ValueKey('us-hero-single-slot'),
                      isDark: isDark,
                    ),
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.82),
              boxShadow: [
                BoxShadow(
                  color: heartColor.withValues(alpha: isDark ? 0.24 : 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                  spreadRadius: -8,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(
              isPaired ? Icons.favorite_rounded : Icons.favorite_border,
              color: heartColor,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroRelationshipAvatar extends StatelessWidget {
  const _HeroRelationshipAvatar({
    super.key,
    required this.label,
    required this.isDark,
    this.alignRight = false,
  });

  final String label;
  final bool isDark;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isDark
            ? LinearGradient(
                begin: alignRight ? Alignment.topRight : Alignment.topLeft,
                end: alignRight ? Alignment.bottomLeft : Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.34),
                  AppTheme.heroGlowPurple.withValues(alpha: 0.2),
                ],
              )
            : LinearGradient(
                begin: alignRight ? Alignment.topRight : Alignment.topLeft,
                end: alignRight ? Alignment.bottomLeft : Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.16),
                  AppTheme.heroPeachLight.withValues(alpha: 0.58),
                ],
              ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.86),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.1),
            blurRadius: 18,
            offset: const Offset(0, 10),
            spreadRadius: -10,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeroAddAvatar extends StatelessWidget {
  const _HeroAddAvatar({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.46),
        border: Border.all(
          color: isDark
              ? AppTheme.warmWhite25
              : colorScheme.primary.withValues(alpha: 0.16),
          width: 1.4,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.add,
        size: 24,
        color: isDark ? AppTheme.warmWhite60 : colorScheme.primary,
      ),
    );
  }
}

class _HeroNameLabel extends StatelessWidget {
  const _HeroNameLabel({
    required this.name,
    required this.genderIcon,
    required this.isDark,
    this.isPlaceholder = false,
  });

  final String name;
  final IconData? genderIcon;
  final bool isDark;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            name,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isPlaceholder
                  ? (isDark
                        ? AppTheme.warmWhite60
                        : colorScheme.onSurfaceVariant)
                  : (isDark ? AppTheme.warmWhite90 : null),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (genderIcon != null) ...[
          const SizedBox(width: 4),
          Icon(genderIcon, size: 16, color: colorScheme.primary),
        ],
      ],
    );
  }
}

/// Invite code display box.
class _InviteCodeBox extends StatelessWidget {
  const _InviteCodeBox({
    required this.code,
    required this.expiryText,
    required this.isDark,
    this.showCopy = false,
    this.onCopy,
  });

  final String code;
  final String expiryText;
  final bool isDark;
  final bool showCopy;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.nightMuted.withValues(alpha: 0.4)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.of(context).isChinese
                      ? '当前邀请码'
                      : 'Current invite code',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  code,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(expiryText, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (showCopy && onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }
}

/// Preference group wrapper for settings.
class _PreferenceGroup extends StatelessWidget {
  const _PreferenceGroup({
    required this.title,
    required this.child,
    required this.isDark,
  });

  final String title;
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isDark ? AppTheme.warmWhite90 : null,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}
