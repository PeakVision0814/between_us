import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/debug_refresh_diagnostics_card.dart';
import '../../shared/widgets/section_header.dart';

class UsScreen extends StatefulWidget {
  const UsScreen({super.key});

  @override
  State<UsScreen> createState() => _UsScreenState();
}

class _UsScreenState extends State<UsScreen> {
  String? _spaceName;
  String? _relationshipStartDate;
  String? _coupleSpaceId;
  int _memberCount = 0;
  bool _loading = true;

  String? _currentInviteCode;
  DateTime? _currentInviteExpiresAt;
  bool _generatingInvite = false;

  @override
  void initState() {
    super.initState();
    _loadSpaceData();
  }

  Future<void> _loadSpaceData() async {
    try {
      final spaceResponse = await Supabase.instance.client
          .from('couple_spaces')
          .select('id, space_name, relationship_start_date')
          .limit(1)
          .maybeSingle();

      if (spaceResponse != null) {
        _coupleSpaceId = spaceResponse['id'] as String;
        _spaceName = spaceResponse['space_name'] as String?;
        _relationshipStartDate = spaceResponse['relationship_start_date'] as String?;

        final membersResponse = await Supabase.instance.client
            .from('couple_memberships')
            .select('id')
            .eq('couple_space_id', _coupleSpaceId!)
            .eq('status', 'active');

        _memberCount = (membersResponse as List).length;
      }
    } catch (_) {
      // Query failed; keep defaults.
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  String _generateRandomCode() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _generateInviteCode() async {
    if (_coupleSpaceId == null || _generatingInvite) return;

    setState(() => _generatingInvite = true);

    try {
      final code = _generateRandomCode();
      final response = await Supabase.instance.client.rpc('create_couple_invite', params: {
        'p_couple_space_id': _coupleSpaceId,
        'p_plain_code': code,
      });

      final data = response as Map<String, dynamic>;
      setState(() {
        _currentInviteCode = code;
        _currentInviteExpiresAt = DateTime.parse(data['expires_at'] as String);
      });
    } catch (_) {
      // Generation failed.
    } finally {
      if (mounted) {
        setState(() => _generatingInvite = false);
      }
    }
  }

  Future<void> _acceptInvite(String code) async {
    try {
      await Supabase.instance.client.rpc('accept_couple_invite', params: {
        'p_plain_code': code,
      });

      await _loadSpaceData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context).isChinese ? '已成功加入空间' : 'Successfully joined the space'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context).isChinese ? '邀请码无效或已过期' : 'Invalid or expired invite code'),
          ),
        );
      }
    }
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
          .update({'space_name': newName}).eq('id', _coupleSpaceId!);
      setState(() => _spaceName = newName);
    } catch (_) {
      if (mounted) {
        final strings = AppStrings.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.isChinese ? '修改失败，请重试' : 'Failed to update, please try again'),
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
            hintText: strings.isChinese ? '请输入对方分享的邀请码' : 'Enter the invite code shared by your partner',
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
                        value: _spaceName ?? strings.spaceNameValue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HeroFact(
                        title: strings.spaceStatusLabel,
                        value: _loading
                            ? '...'
                            : _memberCount >= 2
                                ? (strings.isChinese ? '已激活' : 'Active')
                                : (strings.isChinese ? '等待对方加入' : 'Waiting for partner'),
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
                subtitle: Text(_spaceName ?? strings.spaceNameValue),
                trailing: const Icon(Icons.edit_outlined, size: 20),
                onTap: _showEditSpaceNameDialog,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: Text(strings.inviteStatusTitle),
                subtitle: Text(_loading
                    ? '...'
                    : _memberCount >= 2
                        ? (strings.isChinese ? '已激活' : 'Active')
                        : (strings.isChinese ? '等待对方加入' : 'Waiting for partner')),
              ),
              if (!_loading && _memberCount < 2) ...[
                const Divider(height: 1),
                if (_currentInviteCode != null) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.isChinese ? '邀请码' : 'Invite code',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _currentInviteCode!,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontFamily: 'monospace',
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _currentInviteCode!));
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
                        const SizedBox(height: 8),
                        Text(
                          strings.isChinese
                              ? '有效期至：${_currentInviteExpiresAt!.month}月${_currentInviteExpiresAt!.day}日 ${_currentInviteExpiresAt!.hour}:${_currentInviteExpiresAt!.minute.toString().padLeft(2, '0')}'
                              : 'Expires: ${_currentInviteExpiresAt!.month}/${_currentInviteExpiresAt!.day} ${_currentInviteExpiresAt!.hour}:${_currentInviteExpiresAt!.minute.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _generatingInvite ? null : _generateInviteCode,
                        icon: _generatingInvite
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.vpn_key_outlined),
                        label: Text(strings.isChinese ? '生成邀请码' : 'Generate invite code'),
                      ),
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showInviteCodeDialog,
                      icon: const Icon(Icons.login),
                      label: Text(strings.isChinese ? '输入邀请码加入' : 'Enter invite code to join'),
                    ),
                  ),
                ),
              ],
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
                subtitle: Text(_relationshipStartDate ?? strings.relationshipDateValue),
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
        if (!kReleaseMode) ...[
          const SizedBox(height: 18),
          const SectionHeader(title: 'Debug'),
          const DebugRefreshDiagnosticsCard(),
        ],
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
