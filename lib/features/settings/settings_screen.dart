import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import '../../app/app_theme.dart';
import '../../shared/widgets/page_visual_language.dart';
import 'profile_screen.dart';

class UsScreen extends StatefulWidget {
  const UsScreen({super.key});

  @override
  State<UsScreen> createState() => _UsScreenState();
}

class _UsScreenState extends State<UsScreen> with WidgetsBindingObserver {
  String? _spaceName;
  String? _coupleSpaceId;
  int _memberCount = 0;
  bool _loadingSpaceData = false;

  String? _currentInviteCode;
  DateTime? _currentInviteExpiresAt;
  bool _generatingInvite = false;
  bool _acceptingInvite = false;
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
          .select('id, space_name')
          .eq('id', _coupleSpaceId!)
          .maybeSingle();

      debugPrint('[Space] loaded: $spaceResponse');

      if (spaceResponse != null) {
        _coupleSpaceId = spaceResponse['id'] as String;
        _spaceName = spaceResponse['space_name'] as String?;

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
    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) {
      if (!mounted) return;
      final strings = AppStrings.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.inviteCodeEmptyError)));
      return;
    }

    setState(() => _acceptingInvite = true);
    final appController = AppScope.read(context);

    try {
      await Supabase.instance.client.rpc(
        'accept_couple_invite',
        params: {'p_plain_code': trimmedCode},
      );

      // 刷新 AppController 的空间和成员状态
      await appController.refreshAfterInviteAccepted();

      await _loadSpaceData();

      if (mounted) {
        final strings = AppStrings.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.isChinese ? '已成功加入空间' : 'Successfully joined the space',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[Invite] accept failed: $e');
      if (mounted) {
        final strings = AppStrings.of(context);
        final message = _mapInviteError(e, strings);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) {
        setState(() => _acceptingInvite = false);
      }
    }
  }

  String _mapInviteError(Object error, AppStrings strings) {
    final message = error.toString().toLowerCase();
    // 后端 RPC 对无效、过期、已使用统一抛同一文案，前端不做假区分。
    // 只对"已在配对空间"这个可明确区分的场景单独提示。
    if (message.contains('already belongs to an active couple_space')) {
      return strings.inviteAlreadyPairedError;
    }
    return strings.isChinese ? '邀请码无效或已过期' : 'Invalid or expired invite code';
  }

  void _openProfileScreen(AppController controller, AppStrings strings) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileScreen(controller: controller),
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
          acceptingInvite: _acceptingInvite,
          onGenerateInvite: _generateInviteCode,
          onShowInviteDialog: _showInviteCodeDialog,
        ),
      ),
    );
  }

  void _showInviteCodeDialog() {
    final strings = AppStrings.of(context);
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(strings.isChinese ? '输入邀请码' : 'Enter invite code'),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(
              hintText: strings.isChinese
                  ? '请输入对方分享的邀请码'
                  : 'Enter the invite code shared by your partner',
            ),
            autofocus: true,
            enabled: !_acceptingInvite,
          ),
          actions: [
            TextButton(
              onPressed: _acceptingInvite
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: Text(strings.isChinese ? '取消' : 'Cancel'),
            ),
            FilledButton(
              onPressed: _acceptingInvite
                  ? null
                  : () async {
                      final code = textController.text.trim();
                      if (code.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text(strings.inviteCodeEmptyError)),
                        );
                        return;
                      }
                      Navigator.pop(dialogContext);
                      await _acceptInvite(code);
                    },
              child: _acceptingInvite
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(strings.isChinese ? '加入' : 'Join'),
            ),
          ],
        ),
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
          const SizedBox(height: 16),
          _buildSpaceSection(
            context,
            strings,
            isPaired: isPaired,
            isDark: isDark,
          ),
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
                                    name: isPaired
                                        ? partnerLabel
                                        : (strings.isChinese
                                              ? '邀请 TA'
                                              : 'Invite'),
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
    return _SpaceModule(
      key: const ValueKey('us-space-section'),
      isDark: isDark,
      title: strings.spaceSection,
      entries: [
        _SpaceModuleEntryData(
          icon: Icons.info_outline,
          label: strings.spaceStatusLabel,
          onTap: isPaired ? () {} : null,
        ),
      ],
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
    required this.acceptingInvite,
    required this.onGenerateInvite,
    required this.onShowInviteDialog,
  });

  final AppController controller;
  final bool isPaired;
  final String? partnerName;
  final String? currentInviteCode;
  final DateTime? currentInviteExpiresAt;
  final bool generatingInvite;
  final bool acceptingInvite;
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
                  _SoftAvatar(label: name.characters.first, isDark: isDark),
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
                          strings.isChinese ? '已加入空间' : 'Has joined the space',
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
                  expiryText: _inviteExpiryText(
                    strings,
                    currentInviteExpiresAt!,
                  ),
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
                    onPressed: (generatingInvite || acceptingInvite)
                        ? null
                        : onGenerateInvite,
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
                    onPressed: acceptingInvite ? null : onShowInviteDialog,
                    icon: acceptingInvite
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(
                      acceptingInvite
                          ? strings.inviteAccepting
                          : (strings.isChinese
                                ? '输入邀请码加入'
                                : 'Enter invite code to join'),
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

class _SpaceModule extends StatelessWidget {
  const _SpaceModule({
    super.key,
    required this.isDark,
    required this.title,
    required this.entries,
  });

  final bool isDark;
  final String title;
  final List<_SpaceModuleEntryData> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: isDark ? AppTheme.warmWhite90 : colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppTheme.heroDeepPurple.withValues(alpha: 0.86),
                      AppTheme.nightSurface.withValues(alpha: 0.9),
                      const Color(0xFF12101A).withValues(alpha: 0.92),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.92),
                      AppTheme.heroBlushLight.withValues(alpha: 0.54),
                      AppTheme.heroPeachLight.withValues(alpha: 0.34),
                    ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radius2xl),
            border: Border.all(
              color: isDark
                  ? AppTheme.heroGlowBlush.withValues(alpha: 0.28)
                  : Colors.white.withValues(alpha: 0.86),
              width: isDark ? 0.9 : 1,
            ),
            boxShadow: isDark
                ? AppTheme.shadowCardDarkStrong
                : AppTheme.shadowCardLightStrong,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radius2xl),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: isDark
                            ? const Alignment(0.74, -0.78)
                            : const Alignment(-0.64, -0.9),
                        radius: isDark ? 1.12 : 1.02,
                        colors: isDark
                            ? [
                                AppTheme.heroGlowPurple.withValues(alpha: 0.22),
                                AppTheme.heroGlowBlush.withValues(alpha: 0.07),
                                Colors.transparent,
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.72),
                                AppTheme.heroBlushLight.withValues(alpha: 0.16),
                                Colors.transparent,
                              ],
                        stops: const [0, 0.5, 1],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      for (var index = 0; index < entries.length; index++) ...[
                        _SpaceModuleEntry(data: entries[index], isDark: isDark),
                        if (index != entries.length - 1)
                          const SizedBox(width: 10),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SpaceModuleEntryData {
  const _SpaceModuleEntryData({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
}

class _SpaceModuleEntry extends StatelessWidget {
  const _SpaceModuleEntry({required this.data, required this.isDark});

  final _SpaceModuleEntryData data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconColor = colorScheme.primary;
    final enabled = data.onTap != null;
    final disabledOpacity = 0.4;

    return Semantics(
      button: enabled,
      enabled: enabled,
      label: data.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('us-space-entry-${data.label}'),
          onTap: data.onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Opacity(
              opacity: enabled ? 1.0 : disabledOpacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                iconColor.withValues(alpha: 0.24),
                                AppTheme.heroGlowPurple.withValues(alpha: 0.16),
                                Colors.white.withValues(alpha: 0.04),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.9),
                                iconColor.withValues(alpha: 0.14),
                                AppTheme.heroPeachLight.withValues(alpha: 0.3),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(
                        color: isDark
                            ? iconColor.withValues(alpha: 0.24)
                            : Colors.white.withValues(alpha: 0.82),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withValues(
                            alpha: isDark ? 0.18 : 0.1,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                          spreadRadius: -12,
                        ),
                      ],
                    ),
                    child: Icon(data.icon, color: iconColor, size: 26),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    data.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isDark
                          ? AppTheme.warmWhite90
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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

/// Invite code display box with copy button.
class _InviteCodeBox extends StatelessWidget {
  const _InviteCodeBox({
    required this.code,
    required this.expiryText,
    required this.isDark,
  });

  final String code;
  final String expiryText;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = AppStrings.of(context);

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
                  strings.isChinese ? '当前邀请码' : 'Current invite code',
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
          const SizedBox(width: 8),
          IconButton(
            key: const ValueKey('invite-code-copy-button'),
            icon: const Icon(Icons.copy_rounded, size: 20),
            tooltip: strings.isChinese ? '复制邀请码' : 'Copy invite code',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(strings.inviteCodeCopied)),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
