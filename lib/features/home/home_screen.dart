import 'dart:ui';

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
  NoteItemCopy? _recentNote;
  PlanItemCopy? _recentPlan;

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

    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from('notes')
            .select('body, authored_at')
            .filter('deleted_at', 'is', null)
            .order('authored_at', ascending: false)
            .limit(1)
            .maybeSingle(),
        Supabase.instance.client
            .from('calendar_events')
            .select('title, description, starts_at, event_type')
            .filter('deleted_at', 'is', null)
            .gte('starts_at', DateTime.now().toIso8601String().substring(0, 10))
            .order('starts_at', ascending: true)
            .limit(1)
            .maybeSingle(),
        Supabase.instance.client
            .from('plans')
            .select('title, body, status')
            .filter('deleted_at', 'is', null)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle(),
      ]);

      if (!mounted) return;
      final strings = AppStrings.of(context);

      final noteData = results[0];
      final eventData = results[1];
      final planData = results[2];

      setState(() {
        if (noteData != null) {
          _recentNote = NoteItemCopy(
            author: '',
            timeLabel: _formatTimeAgo(
              DateTime.parse(noteData['authored_at'] as String),
              strings.isChinese,
            ),
            text: noteData['body'] as String,
          );
        }
        if (eventData != null) {
          final startsAt = DateTime.parse(eventData['starts_at'] as String);
          final eventType = eventData['event_type'] as String;
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
        }
        if (planData != null) {
          _recentPlan = PlanItemCopy(
            title: planData['title'] as String,
            body: planData['body'] as String? ?? '',
            statusLabel: _mapPlanStatus(
              planData['status'] as String,
              strings.isChinese,
            ),
            helperLabel: strings.isChinese ? '来自计划' : 'From plans',
          );
        }
        // Data loaded.
      });
    } catch (e) {
      debugPrint('[Home] load failed: $e');
      // Query failed; keep nulls.
    }
  }

  static String _formatTimeAgo(DateTime dt, bool isChinese) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) {
      return isChinese ? '刚刚' : 'Just now';
    }
    if (diff.inHours < 1) {
      return isChinese ? '${diff.inMinutes} 分钟前' : '${diff.inMinutes}m ago';
    }
    if (diff.inDays < 1) {
      return isChinese ? '${diff.inHours} 小时前' : '${diff.inHours}h ago';
    }
    if (diff.inDays < 30) {
      return isChinese ? '${diff.inDays} 天前' : '${diff.inDays}d ago';
    }
    return isChinese ? '${dt.month} 月${dt.day} 日' : '${dt.month}/${dt.day}';
  }

  static CalendarEntryType _mapEventType(String type) => switch (type) {
    'anniversary' => CalendarEntryType.anniversary,
    'reminder' => CalendarEntryType.reminder,
    _ => CalendarEntryType.datePlan,
  };

  static String _mapPlanStatus(String status, bool isChinese) =>
      switch (status) {
        'idea' => isChinese ? '想法中' : 'Idea',
        'planned' => isChinese ? '已安排' : 'Planned',
        'done' => isChinese ? '已完成' : 'Done',
        _ => status,
      };

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final strings = AppStrings.of(context);
    final isPaired = controller.hasActiveCoupleSpace;

    return PageAtmosphere(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeHero(
            displayName: controller.displayName,
            memberCount: controller.memberCount,
            partnerDisplayName: controller.partnerDisplayName,
            nextDate: _nextDate,
            onOpenCalendar: widget.onOpenCalendar,
            onOpenUs: widget.onOpenUs,
            isChinese: strings.isChinese,
          ),
          const SizedBox(height: 24),
          PageSectionHeader(title: strings.nextDateSection),
          const SizedBox(height: 10),
          _DatePreviewCard(
            item: _nextDate,
            onTap: widget.onOpenCalendar,
            isChinese: strings.isChinese,
          ),
          const SizedBox(height: 24),
          PageSectionHeader(title: strings.recentUpdateSection),
          const SizedBox(height: 10),
          _NotePreviewCard(
            note: _recentNote,
            onWriteNote: widget.onWriteNote,
            isChinese: strings.isChinese,
            isPaired: isPaired,
          ),
          const SizedBox(height: 24),
          PageSectionHeader(title: strings.recentPlanSection),
          const SizedBox(height: 10),
          _PlanPreviewCard(
            plan: _recentPlan,
            onTap: widget.onOpenPlansNotes,
            isChinese: strings.isChinese,
          ),
          const SizedBox(height: 24),
          PageSectionHeader(
            title: strings.quickLinksSection,
            subtitle: strings.homeSubtitle,
          ),
          const SizedBox(height: 10),
          _QuickActions(
            onOpenCalendar: widget.onOpenCalendar,
            onCreatePlan: widget.onCreatePlan,
            onWriteNote: widget.onWriteNote,
            isPaired: isPaired,
          ),
        ],
      ),
    );
  }
}

// ─── Home Hero ───────────────────────────────────────────────────────────

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.displayName,
    required this.memberCount,
    required this.partnerDisplayName,
    required this.nextDate,
    required this.onOpenCalendar,
    required this.onOpenUs,
    required this.isChinese,
  });

  final String? displayName;
  final int memberCount;
  final String? partnerDisplayName;
  final CalendarItemCopy? nextDate;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenUs;
  final bool isChinese;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final primaryName =
        _normalizeName(displayName) ?? (isChinese ? '我们' : 'Us');
    final partnerName = _normalizeName(partnerDisplayName);
    final isPaired = memberCount >= 2 && partnerName != null;
    final coupleNames = isPaired
        ? isChinese
              ? '$primaryName 和 $partnerName'
              : '$primaryName & $partnerName'
        : isChinese
        ? '$primaryName · 等待另一半加入'
        : '$primaryName · Waiting for your partner';
    final relationshipStatus = isPaired
        ? (isChinese ? '双人模式' : 'Paired mode')
        : (isChinese ? '个人模式' : 'Solo mode');
    final avatarLabelOne = _firstCharacter(
      primaryName,
      fallback: isChinese ? '我' : 'M',
    );
    final avatarLabelTwo = isPaired
        ? _firstCharacter(partnerName, fallback: isChinese ? '伴' : 'P')
        : (isChinese ? '待' : '+');

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
          boxShadow: isDark
              ? AppTheme.shadowHeroDark
              : AppTheme.shadowHeroLight,
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatars + status badge ──
              Row(
                children: [
                  _HeroAvatarSlot(
                    key: const ValueKey('home-hero-avatar-one'),
                    label: avatarLabelOne,
                    isDark: isDark,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      isPaired ? Icons.favorite_rounded : Icons.favorite_border,
                      color: isDark
                          ? AppTheme.heroGlowBlush
                          : colorScheme.primary,
                      size: 20,
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
                  _HeroAvatarSlot(
                    key: const ValueKey('home-hero-avatar-two'),
                    label: avatarLabelTwo,
                    isDark: isDark,
                  ),
                  const Spacer(),
                  _HeroStatusBadge(
                    key: const ValueKey('home-hero-relationship-status'),
                    icon: Icons.favorite_rounded,
                    label: relationshipStatus,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // ── Couple names ──
              Text(
                coupleNames,
                key: const ValueKey('home-hero-couple-names'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: isDark ? AppTheme.warmWhite90 : colorScheme.onSurface,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  strings.relationshipMood,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppTheme.warmWhite60
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // ── Hero moment (frosted inset) ──
              _HeroMomentPanel(
                item: nextDate,
                onOpenCalendar: onOpenCalendar,
                isChinese: isChinese,
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              // ── Mini status slots ──
              Row(
                children: [
                  Expanded(
                    child: _HeroMiniSlot(
                      icon: Icons.home_work_outlined,
                      label: strings.spaceStatusLabel,
                      value: strings.spaceStatusValue,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroMiniSlot(
                      icon: Icons.nightlight_round,
                      label: strings.overviewChipOne,
                      value: strings.overviewChipTwo,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Go to Us page ──
              SizedBox(
                width: double.infinity,
                child: _HeroGlassButton(
                  onPressed: onOpenUs,
                  isDark: isDark,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 18,
                        color: isDark
                            ? AppTheme.warmWhite90
                            : colorScheme.onSurface,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        strings.goUsLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: isDark
                              ? AppTheme.warmWhite90
                              : colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

  static String _firstCharacter(String? value, {required String fallback}) {
    final normalized = _normalizeName(value);
    if (normalized == null) {
      return fallback;
    }
    return normalized.characters.first;
  }
}

// ─── Hero Avatar Slot ────────────────────────────────────────────────────

class _HeroAvatarSlot extends StatelessWidget {
  const _HeroAvatarSlot({super.key, required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
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
      child: Container(
        width: 44,
        height: 44,
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
      ),
    );
  }
}

// ─── Hero Status Badge ──────────────────────────────────────────────────

class _HeroStatusBadge extends StatelessWidget {
  const _HeroStatusBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.warmWhite90 : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Moment Panel (frosted inset) ──────────────────────────────────

class _HeroMomentPanel extends StatelessWidget {
  const _HeroMomentPanel({
    required this.item,
    required this.onOpenCalendar,
    required this.isChinese,
    required this.isDark,
  });

  final CalendarItemCopy? item;
  final VoidCallback onOpenCalendar;
  final bool isChinese;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: isDark
                ? AppTheme.surfaceInsetGradientDark
                : AppTheme.surfaceInsetGradientLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: isDark
                  ? AppTheme.surfaceBorderDarkSoft
                  : AppTheme.surfaceBorderLightSoft,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              onTap: onOpenCalendar,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: item != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _TypeBadge(label: item!.typeLabel),
                              const Spacer(),
                              Text(
                                item!.countdownLabel,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item!.title,
                            key: ValueKey(
                              'home-featured-calendar-title-${item!.id}',
                            ),
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item!.subtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppTheme.warmWhite60
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item!.dateLabel,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      )
                    : Text(
                        isChinese
                            ? '暂无即将到来的日历事件'
                            : 'No upcoming calendar events',
                        style: theme.textTheme.bodyMedium,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Hero Mini Slot ─────────────────────────────────────────────────────

class _HeroMiniSlot extends StatelessWidget {
  const _HeroMiniSlot({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
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
          Icon(
            icon,
            size: 18,
            color: isDark ? AppTheme.heroGlowBlush : colorScheme.secondary,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppTheme.warmWhite60
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppTheme.warmWhite90 : null,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Glass Button ──────────────────────────────────────────────────

class _HeroGlassButton extends StatelessWidget {
  const _HeroGlassButton({
    required this.onPressed,
    required this.isDark,
    required this.child,
  });

  final VoidCallback onPressed;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Date Preview Card ──────────────────────────────────────────────────

class _DatePreviewCard extends StatelessWidget {
  const _DatePreviewCard({
    required this.item,
    required this.onTap,
    required this.isChinese,
  });

  final CalendarItemCopy? item;
  final VoidCallback onTap;
  final bool isChinese;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PageSurfaceCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius2xl),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: item != null
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PageIconBadge(
                        icon: Icons.event_available_outlined,
                        color: AppTheme.gold,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TypeBadge(label: item!.typeLabel),
                            const SizedBox(height: 10),
                            Text(
                              item!.title,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item!.subtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item!.dateLabel,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item!.countdownLabel,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  )
                : Text(
                    isChinese ? '暂无即将到来的日历事件' : 'No upcoming calendar events',
                    style: theme.textTheme.bodyMedium,
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Note Preview Card ──────────────────────────────────────────────────

class _NotePreviewCard extends StatelessWidget {
  const _NotePreviewCard({
    required this.note,
    required this.onWriteNote,
    required this.isChinese,
    required this.isPaired,
  });

  final NoteItemCopy? note;
  final VoidCallback onWriteNote;
  final bool isChinese;
  final bool isPaired;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    return PageSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageIconBadge(
                  icon: Icons.notes_rounded,
                  color: AppTheme.blush,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(note!.timeLabel, style: theme.textTheme.bodySmall),
                      const SizedBox(height: 7),
                      Text(
                        note!.text,
                        style: theme.textTheme.titleMedium?.copyWith(
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              isChinese ? '还没有随记，写一条吧' : 'No notes yet — write one',
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: isPaired ? onWriteNote : null,
              icon: const Icon(Icons.mode_edit_outline_outlined),
              label: Text(strings.writeNoteLabel),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Plan Preview Card ──────────────────────────────────────────────────

class _PlanPreviewCard extends StatelessWidget {
  const _PlanPreviewCard({
    required this.plan,
    required this.onTap,
    required this.isChinese,
  });

  final PlanItemCopy? plan;
  final VoidCallback onTap;
  final bool isChinese;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return PageSurfaceCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius2xl),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: plan != null
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PageIconBadge(
                        icon: Icons.route_outlined,
                        color: AppTheme.mint,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TypeBadge(label: plan!.statusLabel),
                            const SizedBox(height: 10),
                            Text(
                              plan!.title,
                              style: theme.textTheme.titleMedium,
                            ),
                            if (plan!.body.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                plan!.body,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark
                                      ? AppTheme.warmWhite60
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Text(
                              plan!.helperLabel,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark
                            ? AppTheme.warmWhite60
                            : colorScheme.onSurfaceVariant,
                      ),
                    ],
                  )
                : Text(
                    isChinese ? '还没有计划，新建一个吧' : 'No plans yet — create one',
                    style: theme.textTheme.bodyMedium,
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Quick Actions ──────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onOpenCalendar,
    required this.onCreatePlan,
    required this.onWriteNote,
    required this.isPaired,
  });

  final VoidCallback onOpenCalendar;
  final VoidCallback onCreatePlan;
  final VoidCallback onWriteNote;
  final bool isPaired;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                icon: Icons.add_task_outlined,
                title: strings.createPlanLabel,
                titleKey: const ValueKey('home-quick-action-plan'),
                subtitle: strings.plansSectionTitle,
                color: AppTheme.mint,
                onTap: isPaired ? onCreatePlan : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.edit_note_outlined,
                title: strings.writeNoteLabel,
                titleKey: const ValueKey('home-quick-action-note'),
                subtitle: strings.notesSectionTitle,
                color: AppTheme.blush,
                onTap: isPaired ? onWriteNote : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _WideActionTile(
          icon: Icons.calendar_month_outlined,
          title: strings.goCalendarLabel,
          subtitle: strings.nextDateSection,
          onTap: onOpenCalendar,
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.titleKey,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Key? titleKey;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PageSurfaceCard(
      padding: EdgeInsets.zero,
      variant: PageSurfaceVariant.secondary,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius2xl),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: PageListItem(
              title: title,
              titleKey: titleKey,
              subtitle: subtitle,
              leading: PageIconBadge(icon: icon, color: color, size: 40),
              compact: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _WideActionTile extends StatelessWidget {
  const _WideActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PageSurfaceCard(
      padding: EdgeInsets.zero,
      variant: PageSurfaceVariant.tertiary,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius2xl),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                PageIconBadge(icon: icon, color: AppTheme.gold, size: 40),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.warmWhite60
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? AppTheme.warmWhite60
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Type Badge ─────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
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

class NoteItemCopy {
  const NoteItemCopy({
    required this.author,
    required this.timeLabel,
    required this.text,
  });

  final String author;
  final String timeLabel;
  final String text;
}

class PlanItemCopy {
  const PlanItemCopy({
    required this.title,
    required this.body,
    required this.statusLabel,
    required this.helperLabel,
  });

  final String title;
  final String body;
  final String statusLabel;
  final String helperLabel;
}
