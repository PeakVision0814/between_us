import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_strings.dart';
import '../../app/app_theme.dart';
import '../../app/app_controller.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenCalendar,
    required this.onOpenPlansNotes,
    required this.onOpenUs,
    required this.onCreatePlan,
    required this.onWriteNote,
  });

  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenPlansNotes;
  final VoidCallback onOpenUs;
  final VoidCallback onCreatePlan;
  final VoidCallback onWriteNote;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _quote;
  _AnniversaryCountdown? _nextAnniversary;
  DateTime? _relationshipStartDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.of(context);
    controller.addListener(_onControllerChanged);
    _quote ??= _pickQuote();
    _loadAnniversaryData();
  }

  @override
  void dispose() {
    try {
      final controller = AppScope.read(context);
      controller.removeListener(_onControllerChanged);
    } catch (_) {}
    super.dispose();
  }

  void _onControllerChanged() {
    _loadAnniversaryData();
  }

  String _pickQuote() {
    final quotes = AppStrings.of(context).homeHeroQuotes;
    return quotes[Random().nextInt(quotes.length)];
  }

  Future<void> _loadAnniversaryData() async {
    final controller = AppScope.read(context);
    if (!controller.supabaseReady || !controller.hasActiveCoupleSpace) {
      if (mounted) {
        setState(() {
          _nextAnniversary = null;
          _relationshipStartDate = null;
        });
      }
      return;
    }

    try {
      final spaceId = controller.currentSpaceId!;
      var response = await Supabase.instance.client
          .from('anniversaries')
          .select('type, title, date')
          .eq('couple_space_id', spaceId);

      if (!mounted) return;

      var events = (response as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      // 自动补建缺失的固有纪念日（兼容迁移前创建的空间）
      final hasFirstMet = events.any((e) => e['type'] == 'first_met');
      final hasRelationshipStart = events.any(
        (e) => e['type'] == 'relationship_start',
      );
      if (!hasFirstMet || !hasRelationshipStart) {
        final today = _formatDateForStorage(DateTime.now());
        final toInsert = <Map<String, dynamic>>[];
        if (!hasFirstMet) {
          toInsert.add({
            'couple_space_id': spaceId,
            'type': 'first_met',
            'title': '相识纪念日',
            'date': today,
            'is_custom': false,
          });
        }
        if (!hasRelationshipStart) {
          toInsert.add({
            'couple_space_id': spaceId,
            'type': 'relationship_start',
            'title': '恋爱纪念日',
            'date': today,
            'is_custom': false,
          });
        }
        await Supabase.instance.client.from('anniversaries').insert(toInsert);
        // 重新查询
        response = await Supabase.instance.client
            .from('anniversaries')
            .select('type, title, date')
            .eq('couple_space_id', spaceId);
        if (!mounted) return;
        events = (response as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }

      if (events.isEmpty) {
        if (mounted) {
          setState(() {
            _nextAnniversary = null;
            _relationshipStartDate = null;
          });
        }
        return;
      }

      final now = DateTime.now();
      _AnniversaryCountdown? nearest;
      DateTime? relationshipStart;

      for (final event in events) {
        final date = DateTime.parse(event['date'] as String);
        final title = event['title'] as String;
        final type = event['type'] as String;

        if (type == 'relationship_start') {
          relationshipStart = date;
        }

        var thisYear = DateTime(now.year, date.month, date.day);
        if (thisYear.isBefore(now)) {
          thisYear = DateTime(now.year + 1, date.month, date.day);
        }

        final daysUntil = thisYear.difference(now).inDays;
        final candidate = _AnniversaryCountdown(
          title: title,
          daysUntil: daysUntil,
        );

        if (nearest == null || candidate.daysUntil < nearest.daysUntil) {
          nearest = candidate;
        }
      }

      if (mounted) {
        setState(() {
          _nextAnniversary = nearest;
          _relationshipStartDate = relationshipStart;
        });
      }
    } catch (_) {
      // 查询失败，保持当前状态
    }
  }

  static String _formatDateForStorage(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Future<void> _onRefresh() async {
    final controller = AppScope.read(context);
    await controller.refreshAllData();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppTheme.pageBackgroundDark
                  : AppTheme.pageBackgroundLight,
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppTheme.pageAtmosphereDark
                    : AppTheme.pageAtmosphereLight,
              ),
            ),
          ),
        ),
        RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _HomeHeroCard(
                quote: _quote ?? '',
                memberCount: controller.memberCount,
                partnerDisplayName: controller.partnerDisplayName,
                relationshipStartDate: _relationshipStartDate,
                nextAnniversary: _nextAnniversary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Hero Card ─────────────────────────────────────────────────────────

class _AnniversaryCountdown {
  const _AnniversaryCountdown({required this.title, required this.daysUntil});

  final String title;
  final int daysUntil;
}

class _HomeHeroCard extends StatelessWidget {
  const _HomeHeroCard({
    required this.quote,
    required this.memberCount,
    required this.partnerDisplayName,
    required this.relationshipStartDate,
    this.nextAnniversary,
  });

  final String quote;
  final int memberCount;
  final String? partnerDisplayName;
  final DateTime? relationshipStartDate;
  final _AnniversaryCountdown? nextAnniversary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final strings = AppStrings.of(context);

    final partnerName = _normalizeName(partnerDisplayName);
    final isPaired = memberCount >= 2 && partnerName != null;

    final days = relationshipStartDate != null
        ? DateTime.now().difference(relationshipStartDate!).inDays + 1
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radius2xl),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.heroGradientDark
              : AppTheme.heroGradientLight,
          borderRadius: BorderRadius.circular(AppTheme.radius2xl),
          border: isDark
              ? Border.all(
                  color: AppTheme.heroGlowPurple.withValues(alpha: 0.2),
                  width: 1,
                )
              : null,
          boxShadow: isDark ? AppTheme.shadowHeroDark : AppTheme.shadowHeroLight,
        ),
        child: Stack(
          children: [
            // 氛围光
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? AppTheme.heroAtmosphereDark
                      : AppTheme.heroAtmosphereLight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 第一层：情绪文案
                  Text(
                    quote,
                    key: const ValueKey('home-hero-quote'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppTheme.warmWhite60
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 第二层：在一起天数
                  if (isPaired && days != null) ...[
                    Text(
                      strings.homeHeroDaysTogetherLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppTheme.warmWhite60
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$days',
                          key: const ValueKey('home-hero-days'),
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: isDark
                                ? AppTheme.warmWhite90
                                : colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            strings.homeHeroDaysUnit,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: isDark
                                  ? AppTheme.warmWhite60
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 第三层：纪念日提醒
                  if (isPaired && nextAnniversary != null) ...[
                    Text(
                      strings.homeHeroAnniversaryCountdown(
                        nextAnniversary!.title,
                        nextAnniversary!.daysUntil,
                      ),
                      key: const ValueKey('home-hero-anniversary'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppTheme.warmWhite60
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 第四层：伴侣信息
                  _PartnerInfo(
                    isPaired: isPaired,
                    partnerName: partnerName,
                    strings: strings,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _normalizeName(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}

// ─── 伴侣信息 ──────────────────────────────────────────────────────────

class _PartnerInfo extends StatelessWidget {
  const _PartnerInfo({
    required this.isPaired,
    required this.partnerName,
    required this.strings,
    required this.isDark,
  });

  final bool isPaired;
  final String? partnerName;
  final AppStrings strings;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!isPaired) {
      return Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.5),
              border: Border.all(
                color: isDark
                    ? AppTheme.warmWhite25
                    : colorScheme.primary.withValues(alpha: 0.16),
                width: 1.4,
              ),
            ),
            child: Icon(
              Icons.add,
              size: 20,
              color: isDark ? AppTheme.warmWhite60 : colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            strings.homeHeroWaitingForPartner,
            key: const ValueKey('home-hero-waiting'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppTheme.warmWhite60 : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final label = partnerName!.characters.first;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
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
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.86),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          partnerName!,
          key: const ValueKey('home-hero-partner-name'),
          style: theme.textTheme.titleMedium?.copyWith(
            color: isDark ? AppTheme.warmWhite90 : colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
