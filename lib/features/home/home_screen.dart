import 'package:flutter/material.dart';

import '../../app/app_strings.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/section_header.dart';
import 'widgets/couple_overview_card.dart';

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
    final nextDate = strings.calendarItems.first;
    final recentNote = strings.notes.first;
    final recentPlan = strings.plans.first;

    return AppPage(
      children: [
        Text(
          strings.homeTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(strings.homeSubtitle),
        const SizedBox(height: 20),
        SectionHeader(title: strings.overviewSection),
        const CoupleOverviewCard(),
        const SizedBox(height: 18),
        SectionHeader(title: strings.nextDateSection),
        _DatePreviewCard(item: nextDate, onTap: onOpenCalendar),
        const SizedBox(height: 18),
        SectionHeader(title: strings.recentUpdateSection),
        _NotePreviewCard(note: recentNote, onWriteNote: onWriteNote),
        const SizedBox(height: 18),
        SectionHeader(title: strings.recentPlanSection),
        _PlanPreviewCard(plan: recentPlan, onTap: onOpenPlansNotes),
        const SizedBox(height: 18),
        SectionHeader(title: strings.quickLinksSection),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ActionChip(
              avatar: const Icon(Icons.calendar_month_outlined, size: 18),
              label: Text(strings.goCalendarLabel),
              onPressed: onOpenCalendar,
            ),
            ActionChip(
              avatar: const Icon(Icons.add_task_outlined, size: 18),
              label: Text(strings.createPlanLabel),
              onPressed: onCreatePlan,
            ),
            ActionChip(
              avatar: const Icon(Icons.edit_note_outlined, size: 18),
              label: Text(strings.writeNoteLabel),
              onPressed: onWriteNote,
            ),
            ActionChip(
              avatar: const Icon(Icons.favorite_border, size: 18),
              label: Text(strings.goUsLabel),
              onPressed: onOpenUs,
            ),
          ],
        ),
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

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
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
                    const SizedBox(height: 6),
                    Text(item.subtitle),
                    const SizedBox(height: 10),
                    Text(
                      item.dateLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                item.countdownLabel,
                textAlign: TextAlign.right,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: colorScheme.primary),
              ),
            ],
          ),
        ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${note.author} | ${note.timeLabel}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(note.text, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: onWriteNote,
              icon: const Icon(Icons.edit_note_outlined),
              label: Text(AppStrings.of(context).writeNoteLabel),
            ),
          ],
        ),
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
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TypeBadge(label: plan.statusLabel),
              const SizedBox(height: 10),
              Text(plan.title, style: Theme.of(context).textTheme.titleMedium),
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
