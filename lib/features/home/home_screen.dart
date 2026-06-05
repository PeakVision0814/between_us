import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_strings.dart';
import '../../app/app_theme.dart';
import '../../app/app_controller.dart';
import '../../shared/widgets/page_visual_language.dart';

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
  CalendarItemCopy? _nextDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final appController = AppScope.read(context);
    if (!appController.supabaseReady) {
      debugPrint(
        '[Home] skip load: supabase not ready (${appController.supabaseFailureReason ?? 'unknown'})',
      );
      return;
    }
    if (!appController.hasActiveCoupleSpace) {
      debugPrint('[Home] skip load: no active couple space');
      return;
    }

    try {
      final eventData = await Supabase.instance.client
          .from('calendar_events')
          .select('title, description, starts_at, event_type')
          .filter('deleted_at', 'is', null)
          .gte('starts_at', DateTime.now().toIso8601String().substring(0, 10))
          .order('starts_at', ascending: true)
          .limit(1)
          .maybeSingle();

      if (!mounted) return;
      final strings = AppStrings.of(context);

      if (eventData != null) {
        final startsAt = DateTime.parse(eventData['starts_at'] as String);
        final eventType = eventData['event_type'] as String;
        setState(() {
          _nextDate = CalendarItemCopy(
            id: 'home-featured',
            title: eventData['title'] as String,
            subtitle: eventData['description'] as String? ?? '',
            dateLabel: strings.formatCalendarDate(
              startsAt,
              includeTime: startsAt.hour != 0,
            ),
            countdownLabel: strings.formatCountdownLabel(
              startsAt,
              DateTime.now(),
            ),
            typeLabel: strings.calendarTypeLabel(_mapEventType(eventType)),
          );
        });
      }
    } catch (e) {
      debugPrint('[Home] load failed: $e');
      // Query failed; keep nulls.
    }
  }

  static CalendarEntryType _mapEventType(String type) => switch (type) {
    'anniversary' => CalendarEntryType.anniversary,
    'reminder' => CalendarEntryType.reminder,
    _ => CalendarEntryType.datePlan,
  };

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final isPaired = controller.hasActiveCoupleSpace;

    return PageAtmosphere(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 大卡片：情侣名称 + 头像 + 空间状态
          _HomeCoupleCard(
            displayName: controller.displayName,
            memberCount: controller.memberCount,
            partnerDisplayName: controller.partnerDisplayName,
            onOpenUs: widget.onOpenUs,
          ),
          // 双人态下显示额外信息
          if (isPaired) ...[
            const SizedBox(height: 20),
            // 恋爱天数卡片
            if (controller.relationshipStartDate != null) ...[
              _RelationshipDaysCard(
                startDate: controller.relationshipStartDate!,
              ),
              const SizedBox(height: 16),
            ],
            // 下一个重要事件卡片
            _NextEventCard(
              item: _nextDate,
              onOpenCalendar: widget.onOpenCalendar,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── 情侣卡片（大卡片）────────────────────────────────────────────────

class _HomeCoupleCard extends StatelessWidget {
  const _HomeCoupleCard({
    required this.displayName,
    required this.memberCount,
    required this.partnerDisplayName,
    required this.onOpenUs,
  });

  final String? displayName;
  final int memberCount;
  final String? partnerDisplayName;
  final VoidCallback onOpenUs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final strings = AppStrings.of(context);

    final primaryName = _normalizeName(displayName) ?? strings.selfFallbackName;
    final partnerName = _normalizeName(partnerDisplayName);
    final isPaired = memberCount >= 2 && partnerName != null;

    final avatarLabelOne = primaryName.characters.first;
    final avatarLabelTwo = isPaired
        ? partnerName.characters.first
        : (strings.isChinese ? '待' : '+');

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.heroGradientDark
              : AppTheme.heroGradientLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: isDark
              ? Border.all(
                  color: AppTheme.heroGlowPurple.withValues(alpha: 0.2),
                  width: 1,
                )
              : null,
          boxShadow: isDark ? AppTheme.shadowHeroDark : AppTheme.shadowHeroLight,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            onTap: onOpenUs,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  // 头像对
                  _AvatarPair(
                    avatarOne: avatarLabelOne,
                    avatarTwo: avatarLabelTwo,
                    isPaired: isPaired,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 18),
                  // 名称和状态
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPaired
                              ? '$primaryName & $partnerName'
                              : primaryName,
                          key: const ValueKey('home-hero-couple-names'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: isDark ? AppTheme.warmWhite90 : colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isPaired
                              ? (strings.isChinese ? '双人模式' : 'Paired mode')
                              : (strings.isChinese ? '等待另一半加入' : 'Waiting for partner'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppTheme.warmWhite60
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 箭头
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? AppTheme.warmWhite60 : colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String? _normalizeName(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}

// ─── 头像对组件 ──────────────────────────────────────────────────────

class _AvatarPair extends StatelessWidget {
  const _AvatarPair({
    required this.avatarOne,
    required this.avatarTwo,
    required this.isPaired,
    required this.isDark,
  });

  final String avatarOne;
  final String avatarTwo;
  final bool isPaired;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final heartColor = isDark ? AppTheme.heroGlowBlush : colorScheme.primary;

    return SizedBox(
      width: 80,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: _SingleAvatar(
              label: avatarOne,
              isDark: isDark,
            ),
          ),
          Positioned(
            right: 0,
            child: _SingleAvatar(
              label: avatarTwo,
              isDark: isDark,
              isPlaceholder: !isPaired,
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.82),
            ),
            alignment: Alignment.center,
            child: Icon(
              isPaired ? Icons.favorite_rounded : Icons.favorite_border,
              color: heartColor,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleAvatar extends StatelessWidget {
  const _SingleAvatar({
    required this.label,
    required this.isDark,
    this.isPlaceholder = false,
  });

  final String label;
  final bool isDark;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isPlaceholder
            ? null
            : (isDark
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
                  )),
        color: isPlaceholder
            ? (isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.46))
            : null,
        border: Border.all(
          color: isPlaceholder
              ? (isDark
                  ? AppTheme.warmWhite25
                  : colorScheme.primary.withValues(alpha: 0.16))
              : (isDark
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.86)),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: isPlaceholder
              ? (isDark ? AppTheme.warmWhite60 : colorScheme.primary)
              : colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── 恋爱天数卡片 ─────────────────────────────────────────────────────

class _RelationshipDaysCard extends StatelessWidget {
  const _RelationshipDaysCard({
    required this.startDate,
  });

  final DateTime startDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final strings = AppStrings.of(context);
    final days = DateTime.now().difference(startDate).inDays + 1;

    return PageSurfaceCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha: 0.12),
            ),
            child: Icon(
              Icons.favorite_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.relationshipStartDateLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppTheme.warmWhite60
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.relationshipStartDaysLabel(days),
                  key: const ValueKey('home-relationship-days'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 下一个事件卡片 ─────────────────────────────────────────────────────

class _NextEventCard extends StatelessWidget {
  const _NextEventCard({
    required this.item,
    required this.onOpenCalendar,
  });

  final CalendarItemCopy? item;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final strings = AppStrings.of(context);

    return PageSurfaceCard(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius2xl),
          onTap: onOpenCalendar,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: item != null
                ? Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.gold.withValues(alpha: 0.12),
                        ),
                        child: const Icon(
                          Icons.event_available_outlined,
                          color: AppTheme.gold,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.nextEventLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppTheme.warmWhite60
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item!.title,
                              key: const ValueKey('home-next-event-title'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item!.countdownLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark
                            ? AppTheme.warmWhite60
                            : colorScheme.onSurfaceVariant,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.white.withValues(alpha: 0.55),
                        ),
                        child: Icon(
                          Icons.event_available_outlined,
                          color: isDark
                              ? AppTheme.warmWhite60
                              : colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.nextEventLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppTheme.warmWhite60
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              strings.noUpcomingEvent,
                              style: theme.textTheme.bodyMedium?.copyWith(
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
          ),
        ),
      ),
    );
  }
}

// ─── Data models ────────────────────────────────────────────────────────

class CalendarItemCopy {
  const CalendarItemCopy({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.dateLabel,
    required this.countdownLabel,
    required this.typeLabel,
  });

  final String id;
  final String title;
  final String subtitle;
  final String dateLabel;
  final String countdownLabel;
  final String typeLabel;
}
