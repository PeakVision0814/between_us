import 'package:flutter/material.dart';

import '../../app/app_strings.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/section_header.dart';

class PlansNotesScreen extends StatelessWidget {
  const PlansNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  strings.plansNotesLeadTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(strings.plansNotesLeadSubtitle),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ActionPill(label: strings.addPlanLabel),
                    _ActionPill(label: strings.addNoteLabel),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader(title: strings.plansSectionTitle),
        _SectionIntro(text: strings.plansSectionSubtitle),
        ...strings.plans.map((plan) => _PlanCard(plan: plan)),
        const SizedBox(height: 18),
        SectionHeader(title: strings.notesSectionTitle),
        _SectionIntro(text: strings.notesSectionSubtitle),
        ...strings.notes.map((note) => _NoteCard(note: note)),
      ],
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final PlanItemCopy plan;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  plan.statusLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(plan.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(plan.body),
              const SizedBox(height: 12),
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

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final NoteItemCopy note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.author,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    note.timeLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(note.text),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
