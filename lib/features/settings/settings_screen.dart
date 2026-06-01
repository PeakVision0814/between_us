import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/section_header.dart';
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

    return AppPage(
      children: [
        _buildRelationshipHero(
          context,
          strings,
          selfName: selfName,
          partnerName: partnerName,
          isPaired: isPaired,
        ),
        const SizedBox(height: 20),
        SectionHeader(title: strings.isChinese ? '我的资料' : 'My profile'),
        _buildMyProfileSection(context, strings, controller),
        const SizedBox(height: 20),
        SectionHeader(title: strings.isChinese ? 'TA 的资料' : 'Partner profile'),
        isPaired
            ? _buildPartnerProfileSection(context, strings, partnerName)
            : _buildSingleInviteSection(context, strings),
        const SizedBox(height: 20),
        SectionHeader(title: strings.spaceSection),
        _buildSpaceSection(context, strings, isPaired: isPaired),
        const SizedBox(height: 20),
        SectionHeader(title: strings.settingsMoreTitle),
        _buildSettingsEntrySection(context, strings),
      ],
    );
  }

  Widget _buildRelationshipHero(
    BuildContext context,
    AppStrings strings, {
    required String selfName,
    required String? partnerName,
    required bool isPaired,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final heroTitle = isPaired
        ? strings.isChinese
              ? '$selfName 和 $partnerName'
              : '$selfName & $partnerName'
        : strings.isChinese
        ? '$selfName · 等待另一半'
        : '$selfName · Waiting for your partner';

    return Card(
      key: const ValueKey('us-hero-section'),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.95),
              colorScheme.secondaryContainer.withValues(alpha: 0.88),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.usTitle,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSecondaryContainer.withValues(
                    alpha: 0.75,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                heroTitle,
                key: const ValueKey('us-hero-title'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isPaired
                    ? _relationshipHeroSubtitle(strings)
                    : _singleHeroSubtitle(strings),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSecondaryContainer.withValues(
                    alpha: 0.82,
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 18,
                    ),
                    child: Icon(
                      isPaired ? Icons.favorite_rounded : Icons.favorite_border,
                      color: colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: isPaired
                        ? _HeroPersonSlot(
                            key: const ValueKey('us-hero-partner-slot'),
                            title: strings.isChinese ? 'TA' : 'Partner',
                            name:
                                partnerName ??
                                (strings.isChinese ? 'TA' : 'Partner'),
                            avatarLabel: _avatarLabel(
                              partnerName,
                              fallback: strings.isChinese ? 'TA' : 'P',
                            ),
                          )
                        : _HeroInviteSlot(
                            key: const ValueKey('us-hero-single-slot'),
                            title: strings.isChinese
                                ? '邀请 TA 加入'
                                : 'Invite your partner',
                            subtitle: strings.isChinese
                                ? '等 TA 加入后，这里会开始真正像一个两个人的空间。'
                                : 'Once they join, this page starts to feel like a space for two.',
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroChip(
                    key: const ValueKey('us-hero-status'),
                    label: _relationshipStatusLabel(
                      strings,
                      isPaired: isPaired,
                    ),
                  ),
                  _HeroChip(label: _spaceSummaryLabel(strings)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyProfileSection(
    BuildContext context,
    AppStrings strings,
    AppController controller,
  ) {
    return _PanelCard(
      key: const ValueKey('us-my-profile-section'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _SectionValueRow(
              label: strings.isChinese ? '昵称' : 'Display name',
              value: _resolvedSelfName(controller, strings),
              valueKey: const ValueKey('us-my-profile-display-name'),
            ),
            const Divider(height: 28),
            _SectionValueRow(
              label: strings.isChinese ? '性别' : 'Gender',
              value: _genderLabel(strings, controller.gender),
              valueKey: const ValueKey('us-my-profile-gender'),
            ),
            const Divider(height: 28),
            _SectionValueRow(
              label: strings.isChinese ? '生日' : 'Birthday',
              value: _birthdayLabel(strings, controller.birthday),
              valueKey: const ValueKey('us-my-profile-birthday'),
              isPlaceholder: controller.birthday == null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerProfileSection(
    BuildContext context,
    AppStrings strings,
    String partnerName,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _PanelCard(
      key: const ValueKey('us-partner-profile-section'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AvatarBadge(
                  label: _avatarLabel(
                    partnerName,
                    fallback: strings.isChinese ? 'TA' : 'P',
                  ),
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
                      const SizedBox(height: 4),
                      Text(
                        strings.isChinese
                            ? '本轮先安全展示昵称，更多资料会在后续同步。'
                            : 'This round safely shows the nickname first. More details can come later.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                strings.isChinese
                    ? 'TA 的性别、生日等资料本轮还不主动深读，先把结构稳定下来。'
                    : 'Partner fields like gender and birthday stay out of scope for now while the structure settles first.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleInviteSection(BuildContext context, AppStrings strings) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _PanelCard(
      key: const ValueKey('us-invite-placeholder-section'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.mark_email_unread_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
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
                  ? '现在还是单人模式。等 TA 加入后，这里会开始展示属于你们两个人的资料结构。'
                  : 'You are still in solo mode. Once your partner joins, this section will start showing your shared two-person structure.',
              style: theme.textTheme.bodyMedium,
            ),
            if (_currentInviteCode != null &&
                _currentInviteExpiresAt != null) ...[
              const SizedBox(height: 16),
              Container(
                key: const ValueKey('us-single-invite-code'),
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.45,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.isChinese ? '当前邀请码' : 'Current invite code',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentInviteCode!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _inviteExpiryText(strings, _currentInviteExpiresAt!),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpaceSection(
    BuildContext context,
    AppStrings strings, {
    required bool isPaired,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _PanelCard(
      key: const ValueKey('us-space-section'),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.home_work_outlined),
            title: Text(strings.spaceNameTitle),
            subtitle: Text(_spaceName ?? strings.spaceNameValue),
            trailing: const Icon(Icons.edit_outlined, size: 20),
            onTap: _showEditSpaceNameDialog,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: Text(strings.spaceStatusLabel),
            subtitle: Text(
              _relationshipStatusLabel(strings, isPaired: isPaired),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text(strings.inviteStatusTitle),
            subtitle: Text(_inviteSummaryText(strings, isPaired: isPaired)),
          ),
          if (_currentInviteCode != null &&
              _currentInviteExpiresAt != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.45,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.isChinese ? '邀请码摘要' : 'Invite summary',
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentInviteCode!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily: 'monospace',
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _inviteExpiryText(
                              strings,
                              _currentInviteExpiresAt!,
                            ),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
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
                  ],
                ),
              ),
            ),
          ],
          if (!isPaired) ...[
            const Divider(height: 1),
            Padding(
              key: const ValueKey('us-space-invite-actions'),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                  const SizedBox(height: 12),
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
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.event_outlined),
            title: Text(strings.relationshipDateTitle),
            subtitle: Text(_relationshipDateValue(strings)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsEntrySection(BuildContext context, AppStrings strings) {
    return _PanelCard(
      key: const ValueKey('us-settings-entry-section'),
      child: ListTile(
        key: const ValueKey('open-settings-more-tile'),
        leading: const Icon(Icons.tune_rounded),
        title: Text(strings.settingsMoreTitle),
        subtitle: Text(strings.settingsMoreSubtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: _openSettingsMore,
      ),
    );
  }

  Widget _buildPreferencesSection(
    BuildContext context,
    AppStrings strings,
    AppController controller,
  ) {
    return _PanelCard(
      key: const ValueKey('us-preferences-section'),
      child: Column(
        children: [
          _PreferenceGroup(
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
          _PreferenceGroup(
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
    );
  }

  Widget _buildSignOutSection(
    BuildContext context,
    AppStrings strings,
    AppController controller,
  ) {
    return _PanelCard(
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
            : const Icon(Icons.chevron_right),
        enabled: !controller.signOutInProgress,
        onTap: _confirmSignOut,
      ),
    );
  }

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
          ? '已经有属于你们两个人的空间了，资料、规则和偏好会慢慢长出来。'
          : 'Your shared space is already in place, and the rest of the profile details can grow from here.';
    }

    return strings.isChinese
        ? '你们已经连到同一个空间，接下来会继续补齐更完整的双人信息。'
        : 'You are already connected to the same space, and fuller two-person details can come next.';
  }

  String _singleHeroSubtitle(AppStrings strings) {
    return strings.isChinese
        ? '先把自己的资料和空间准备好，等 TA 加入后，这里就会自然变成两个人的页面。'
        : 'Set up your own details and space first. Once your partner joins, this page will naturally turn into a page for two.';
  }

  String _spaceSummaryLabel(AppStrings strings) {
    final name = _normalizeName(_spaceName);
    if (name != null) {
      return name;
    }
    return strings.isChinese ? '共享空间已准备' : 'Shared space ready';
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

class _PanelCard extends StatelessWidget {
  const _PanelCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(clipBehavior: Clip.antiAlias, child: child);
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.label, this.size = 52});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primary.withValues(alpha: 0.12),
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

class _HeroPersonSlot extends StatelessWidget {
  const _HeroPersonSlot({
    super.key,
    required this.title,
    required this.name,
    required this.avatarLabel,
  });

  final String title;
  final String name;
  final String avatarLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _AvatarBadge(label: avatarLabel),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _HeroInviteSlot extends StatelessWidget {
  const _HeroInviteSlot({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AvatarBadge(label: '＋', size: 44),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _SectionValueRow extends StatelessWidget {
  const _SectionValueRow({
    required this.label,
    required this.value,
    this.valueKey,
    this.isPlaceholder = false,
  });

  final String label;
  final String value;
  final Key? valueKey;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            key: valueKey,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isPlaceholder ? colorScheme.onSurfaceVariant : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _PreferenceGroup extends StatelessWidget {
  const _PreferenceGroup({required this.title, required this.child});

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
