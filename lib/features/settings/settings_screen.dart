import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import '../../app/app_theme.dart';
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
    final effectiveMemberCount = max(_memberCount, controller.memberCount);
    final selfName = _resolvedSelfName(controller, strings);
    final partnerName = _resolvedPartnerName(controller);
    final isPaired = effectiveMemberCount >= 2 && partnerName != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, isDark ? 8 : 4, 16, 32),
      children: [
        _buildRelationshipHero(
          context,
          strings,
          selfName: selfName,
          partnerName: partnerName,
          isPaired: isPaired,
          isDark: isDark,
        ),
        const SizedBox(height: 24),
        _SectionLabel(
          title: strings.isChinese ? '我的资料' : 'My profile',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildMyProfileSection(context, strings, controller, isDark: isDark),
        const SizedBox(height: 24),
        _SectionLabel(
          title: strings.isChinese ? 'TA 的资料' : 'Partner profile',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        isPaired
            ? _buildPartnerProfileSection(
                context,
                strings,
                partnerName,
                isDark: isDark,
              )
            : _buildSingleInviteSection(context, strings, isDark: isDark),
        const SizedBox(height: 24),
        _SectionLabel(title: strings.spaceSection, isDark: isDark),
        const SizedBox(height: 10),
        _buildSpaceSection(context, strings, isPaired: isPaired, isDark: isDark),
        const SizedBox(height: 24),
        _SectionLabel(title: strings.settingsMoreTitle, isDark: isDark),
        const SizedBox(height: 10),
        _buildSettingsEntrySection(context, strings, isDark: isDark),
      ],
    );
  }

  // ─── Relationship Hero ──────────────────────────────────────────────

  Widget _buildRelationshipHero(
    BuildContext context,
    AppStrings strings, {
    required String selfName,
    required String? partnerName,
    required bool isPaired,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final heroTitle = isPaired
        ? strings.isChinese
              ? '$selfName 和 $partnerName'
              : '$selfName & $partnerName'
        : selfName;

    return Container(
      key: const ValueKey('us-hero-section'),
      decoration: BoxDecoration(
        gradient: isDark ? AppTheme.heroGradientDark : AppTheme.heroGradientLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: isDark ? AppTheme.shadowHeroDark : AppTheme.shadowHeroLight,
        border: isDark
            ? Border.all(
                color: AppTheme.heroGlowPurple.withValues(alpha: 0.2),
                width: 1,
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Page label ──
            Text(
              strings.usTitle,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isDark
                    ? AppTheme.warmWhite60
                    : colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),

            // ── Couple title ──
            Text(
              heroTitle,
              key: const ValueKey('us-hero-title'),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: isDark ? AppTheme.warmWhite90 : colorScheme.onSurface,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),

            // ── Subtitle ──
            if (isPaired) ...[
              Text(
                _relationshipHeroSubtitle(strings),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppTheme.warmWhite60
                      : colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
            ] else
              const SizedBox(height: 28),

            // ── Person slots ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _HeroPersonSlot(
                    key: const ValueKey('us-hero-self-slot'),
                    title: strings.isChinese ? '我' : 'Me',
                    name: selfName,
                    avatarLabel: _avatarLabel(
                      selfName,
                      fallback: strings.isChinese ? '我' : 'M',
                    ),
                    isDark: isDark,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 22,
                  ),
                  child: Icon(
                    isPaired ? Icons.favorite_rounded : Icons.favorite_border,
                    color: isDark
                        ? AppTheme.heroGlowBlush
                        : colorScheme.primary,
                    size: 22,
                    shadows: isDark
                        ? [
                            Shadow(
                              color: AppTheme.heroGlowBlush.withValues(
                                alpha: 0.5,
                              ),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                ),
                Expanded(
                  child: isPaired
                      ? _HeroPersonSlot(
                          key: const ValueKey('us-hero-partner-slot'),
                          title: strings.isChinese ? 'TA' : 'Partner',
                          name: partnerName ?? (strings.isChinese ? 'TA' : 'Partner'),
                          avatarLabel: _avatarLabel(
                            partnerName,
                            fallback: strings.isChinese ? 'TA' : 'P',
                          ),
                          isDark: isDark,
                        )
                      : _HeroInviteSlot(
                          key: const ValueKey('us-hero-single-slot'),
                          title: strings.isChinese ? '邀请 TA' : 'Invite',
                          subtitle: '',
                          isDark: isDark,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Status chips ──
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _HeroChip(
                  key: const ValueKey('us-hero-status'),
                  label: _relationshipStatusLabel(
                    strings,
                    isPaired: isPaired,
                  ),
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── My Profile ─────────────────────────────────────────────────────

  Widget _buildMyProfileSection(
    BuildContext context,
    AppStrings strings,
    AppController controller, {
    required bool isDark,
  }) {
    return _UsCard(
      isDark: isDark,
      key: const ValueKey('us-my-profile-section'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Column(
          children: [
            _ProfileRow(
              label: strings.isChinese ? '昵称' : 'Display name',
              value: _resolvedSelfName(controller, strings),
              valueKey: const ValueKey('us-my-profile-display-name'),
              isDark: isDark,
            ),
            _UsDivider(isDark: isDark),
            _ProfileRow(
              label: strings.isChinese ? '性别' : 'Gender',
              value: _genderLabel(strings, controller.gender),
              valueKey: const ValueKey('us-my-profile-gender'),
              isDark: isDark,
            ),
            _UsDivider(isDark: isDark),
            _ProfileRow(
              label: strings.isChinese ? '生日' : 'Birthday',
              value: _birthdayLabel(strings, controller.birthday),
              valueKey: const ValueKey('us-my-profile-birthday'),
              isPlaceholder: controller.birthday == null,
              isDark: isDark,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Partner Profile ────────────────────────────────────────────────

  Widget _buildPartnerProfileSection(
    BuildContext context,
    AppStrings strings,
    String partnerName, {
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _UsCard(
      isDark: isDark,
      key: const ValueKey('us-partner-profile-section'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SoftAvatar(
                  label: _avatarLabel(
                    partnerName,
                    fallback: strings.isChinese ? 'TA' : 'P',
                  ),
                  isDark: isDark,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partnerName,
                        key: const ValueKey('us-partner-name'),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        strings.isChinese
                            ? '这是 TA 在这里留下的名字。'
                            : 'This is the name your partner uses here.',
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.nightMuted.withValues(alpha: 0.4)
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.35,
                      ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
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
    );
  }

  // ─── Single Invite Section ──────────────────────────────────────────

  Widget _buildSingleInviteSection(
    BuildContext context,
    AppStrings strings, {
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _UsCard(
      isDark: isDark,
      key: const ValueKey('us-invite-placeholder-section'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _IconContainer(
                  icon: Icons.mark_email_unread_outlined,
                  isDark: isDark,
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
            if (_currentInviteCode != null &&
                _currentInviteExpiresAt != null) ...[
              const SizedBox(height: 16),
              _InviteCodeBox(
                code: _currentInviteCode!,
                expiryText: _inviteExpiryText(strings, _currentInviteExpiresAt!),
                isDark: isDark,
              ),
            ],
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
                  Clipboard.setData(
                    ClipboardData(text: _currentInviteCode!),
                  );
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

  String _genderLabel(AppStrings strings, String? gender) {
    return switch (gender) {
      AppController.genderMale => strings.isChinese ? '男生' : 'Male',
      AppController.genderFemale => strings.isChinese ? '女生' : 'Female',
      _ => strings.isChinese ? '尚未补充' : 'Not set yet',
    };
  }

  String _birthdayLabel(AppStrings strings, DateTime? birthday) {
    if (birthday == null) {
      return strings.isChinese
          ? '还没有填写，之后也可以再补。'
          : 'Not added yet. You can fill this in later.';
    }

    final month = birthday.month.toString().padLeft(2, '0');
    final day = birthday.day.toString().padLeft(2, '0');
    return strings.isChinese
        ? '${birthday.year} 年 $month 月 $day 日'
        : '${birthday.year}-$month-$day';
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

  String _relationshipHeroSubtitle(AppStrings strings) {
    if (_relationshipStartDate != null) {
      return strings.isChinese
          ? '属于你们两个人的空间。'
          : 'A space that belongs to both of you.';
    }

    return strings.isChinese
        ? '你们已经拥有一个共同空间。'
        : 'You already share a space together.';
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
// Private visual components
// ═══════════════════════════════════════════════════════════════════════

/// Section label — softer than the old SectionHeader.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.isDark});

  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: isDark ? AppTheme.warmWhite60 : null,
        letterSpacing: 0.2,
      ),
    );
  }
}

/// Unified card for the Us page — clean borders, soft elevation.
class _UsCard extends StatelessWidget {
  const _UsCard({super.key, required this.child, this.isDark = false});

  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: isDark ? AppTheme.nightElevated : AppTheme.cardSurfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(
          color: isDark
              ? AppTheme.cardBorderDark
              : AppTheme.cardBorderLight,
          width: 0.5,
        ),
      ),
      shadowColor: Colors.transparent,
      margin: EdgeInsets.zero,
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
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 20,
      endIndent: 20,
      color: isDark
          ? AppTheme.nightBorder.withValues(alpha: 0.5)
          : AppTheme.warmGray200.withValues(alpha: 0.5),
    );
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
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 4,
        right: 4,
        top: 16,
        bottom: isLast ? 16 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppTheme.warmWhite60
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              key: valueKey,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isPlaceholder
                    ? (isDark
                        ? AppTheme.warmWhite25
                        : Theme.of(context).colorScheme.onSurfaceVariant)
                    : null,
              ),
            ),
          ),
        ],
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveIconColor = iconColor ?? colorScheme.primary;

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 14,
          bottom: isLast ? 18 : 14,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              _IconContainer(
                icon: icon!,
                color: effectiveIconColor,
                isDark: isDark,
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppTheme.warmWhite60
                            : colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[trailing!],
          ],
        ),
      ),
    );
  }
}

/// Small icon container used in cards.
class _IconContainer extends StatelessWidget {
  const _IconContainer({
    required this.icon,
    required this.isDark,
    this.color,
  });

  final IconData icon;
  final Color? color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Icon(icon, color: effectiveColor, size: 20),
    );
  }
}

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

/// Hero person slot — frosted glass feel.
class _HeroPersonSlot extends StatelessWidget {
  const _HeroPersonSlot({
    super.key,
    required this.title,
    required this.name,
    required this.avatarLabel,
    required this.isDark,
  });

  final String title;
  final String name;
  final String avatarLabel;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _HeroAvatar(label: avatarLabel, isDark: isDark),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: isDark
                  ? AppTheme.warmWhite60
                  : colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark ? AppTheme.warmWhite90 : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero avatar with gradient background.
class _HeroAvatar extends StatelessWidget {
  const _HeroAvatar({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.3),
                  AppTheme.heroGlowPurple.withValues(alpha: 0.2),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.15),
                  AppTheme.heroPeachLight.withValues(alpha: 0.5),
                ],
              ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ]
            : null,
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

/// Hero invite slot for single state.
class _HeroInviteSlot extends StatelessWidget {
  const _HeroInviteSlot({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.1),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.add,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark ? AppTheme.warmWhite90 : null,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppTheme.warmWhite60
                    : colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Hero status chip — soft translucent.
class _HeroChip extends StatelessWidget {
  const _HeroChip({super.key, required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: 13,
          color: isDark ? AppTheme.warmWhite90 : null,
        ),
      ),
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
                Text(
                  expiryText,
                  style: theme.textTheme.bodySmall,
                ),
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
