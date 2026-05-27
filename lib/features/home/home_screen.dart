import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../app/app_strings.dart';
import '../../shared/widgets/app_page.dart';

class HomeScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final nextDate = strings.calendarFeaturedItem;
    final recentNote = strings.notes.first;
    final recentPlan = strings.plans.first;

    return AppPage(
      children: [
        _HomeHero(
          nextDate: nextDate,
          onOpenCalendar: onOpenCalendar,
          onOpenUs: onOpenUs,
        ),
        const SizedBox(height: 22),
        _NextDatePanel(item: nextDate, onTap: onOpenCalendar),
        const SizedBox(height: 22),
        _RecentPreviewPanel(
          note: recentNote,
          plan: recentPlan,
          onOpenPlansNotes: onOpenPlansNotes,
          onWriteNote: onWriteNote,
        ),
        const SizedBox(height: 22),
        _PrimaryActions(
          onOpenCalendar: onOpenCalendar,
          onCreatePlan: onCreatePlan,
          onWriteNote: onWriteNote,
        ),
      ],
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.nextDate,
    required this.onOpenCalendar,
    required this.onOpenUs,
  });

  final CalendarItemCopy nextDate;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenUs;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colorScheme.brightness == Brightness.light
              ? const [Color(0xFFFFEFE7), Color(0xFFFFF9F1), Color(0xFFEAF7F2)]
              : const [Color(0xFF2A2024), Color(0xFF1C181A), Color(0xFF172421)],
        ),
        border: Border.all(color: colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -36,
            top: -34,
            child: _SoftDisc(size: 142, color: AppTheme.blush),
          ),
          const Positioned(
            left: -28,
            bottom: -44,
            child: _SoftDisc(size: 118, color: AppTheme.mint),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _AvatarPair(labelOne: strings.avatarLabelOne, labelTwo: strings.avatarLabelTwo),
                    const Spacer(),
                    _QuietBadge(
                      icon: Icons.favorite_rounded,
                      label: strings.relationshipStatus,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  strings.coupleNames,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 30,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                    strings.relationshipMood,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 22),
                _HeroMoment(item: nextDate, onOpenCalendar: onOpenCalendar),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStatus(
                        icon: Icons.home_work_outlined,
                        label: strings.spaceStatusLabel,
                        value: strings.spaceStatusValue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStatus(
                        icon: Icons.nightlight_round,
                        label: strings.overviewChipOne,
                        value: strings.overviewChipTwo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onOpenUs,
                  icon: const Icon(Icons.favorite_border),
                  label: Text(strings.goUsLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMoment extends StatelessWidget {
  const _HeroMoment({required this.item, required this.onOpenCalendar});

  final CalendarItemCopy item;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpenCalendar,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _TypeBadge(label: item.typeLabel),
                  const Spacer(),
                  Text(
                    item.countdownLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                key: ValueKey('home-featured-calendar-title-${item.id}'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(item.subtitle),
              const SizedBox(height: 8),
              Text(
                item.dateLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryActions extends StatelessWidget {
  const _PrimaryActions({
    required this.onOpenCalendar,
    required this.onCreatePlan,
    required this.onWriteNote,
  });

  final VoidCallback onOpenCalendar;
  final VoidCallback onCreatePlan;
  final VoidCallback onWriteNote;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: strings.quickLinksSection,
          subtitle: strings.homeSubtitle,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.add_task_outlined,
                title: strings.createPlanLabel,
                subtitle: strings.plansSectionTitle,
                color: AppTheme.mint,
                onTap: onCreatePlan,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                icon: Icons.edit_note_outlined,
                title: strings.writeNoteLabel,
                subtitle: strings.notesSectionTitle,
                color: AppTheme.blush,
                onTap: onWriteNote,
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

class _NextDatePanel extends StatelessWidget {
  const _NextDatePanel({required this.item, required this.onTap});

  final CalendarItemCopy item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: strings.nextDateSection),
        const SizedBox(height: 12),
        _DatePreviewCard(item: item, onTap: onTap),
      ],
    );
  }
}

class _RecentPreviewPanel extends StatelessWidget {
  const _RecentPreviewPanel({
    required this.note,
    required this.plan,
    required this.onOpenPlansNotes,
    required this.onWriteNote,
  });

  final NoteItemCopy note;
  final PlanItemCopy plan;
  final VoidCallback onOpenPlansNotes;
  final VoidCallback onWriteNote;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: strings.recentUpdateSection),
        const SizedBox(height: 12),
        _NotePreviewCard(note: note, onWriteNote: onWriteNote),
        const SizedBox(height: 14),
        _SectionTitle(title: strings.recentPlanSection),
        const SizedBox(height: 12),
        _PlanPreviewCard(plan: plan, onTap: onOpenPlansNotes),
      ],
    );
  }
}

class _DatePreviewCard extends StatelessWidget {
  const _DatePreviewCard({required this.item, required this.onTap});

  final CalendarItemCopy item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _SurfacePanel(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconTile(icon: Icons.event_available_outlined, color: AppTheme.gold),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TypeBadge(label: item.typeLabel),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 5),
                Text(item.subtitle),
                const SizedBox(height: 10),
                Text(
                  item.dateLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            item.countdownLabel,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

class _NotePreviewCard extends StatelessWidget {
  const _NotePreviewCard({required this.note, required this.onWriteNote});

  final NoteItemCopy note;
  final VoidCallback onWriteNote;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return _SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconTile(icon: Icons.notes_rounded, color: AppTheme.blush),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${note.author} · ${note.timeLabel}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      note.text,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: onWriteNote,
              icon: const Icon(Icons.mode_edit_outline_outlined),
              label: Text(strings.writeNoteLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanPreviewCard extends StatelessWidget {
  const _PlanPreviewCard({required this.plan, required this.onTap});

  final PlanItemCopy plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconTile(icon: Icons.route_outlined, color: AppTheme.mint),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TypeBadge(label: plan.statusLabel),
                const SizedBox(height: 10),
                Text(
                  plan.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(plan.body),
                const SizedBox(height: 10),
                Text(
                  plan.helperLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconTile(icon: icon, color: color),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
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
    return _SurfacePanel(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _IconTile(icon: icon, color: AppTheme.gold),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _SurfacePanel extends StatelessWidget {
  const _SurfacePanel({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colorScheme.outline),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AvatarPair extends StatelessWidget {
  const _AvatarPair({required this.labelOne, required this.labelTwo});

  final String labelOne;
  final String labelTwo;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 42,
      child: Stack(
        children: [
          _AvatarDot(label: labelOne, color: AppTheme.blush),
          Positioned(
            left: 28,
            child: _AvatarDot(label: labelTwo, color: AppTheme.mint),
          ),
        ],
      ),
    );
  }
}

class _AvatarDot extends StatelessWidget {
  const _AvatarDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 3,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _QuietBadge extends StatelessWidget {
  const _QuietBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MiniStatus extends StatelessWidget {
  const _MiniStatus({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.secondary),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 3),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _SoftDisc extends StatelessWidget {
  const _SoftDisc({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
    );
  }
}

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
        borderRadius: BorderRadius.circular(999),
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
