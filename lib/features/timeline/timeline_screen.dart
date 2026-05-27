import 'package:flutter/material.dart';

import '../../app/app_strings.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/section_header.dart';

enum PlansNotesMode { overview, plan, note }

class PlansNotesScreen extends StatefulWidget {
  const PlansNotesScreen({super.key, this.mode = PlansNotesMode.overview});

  final PlansNotesMode mode;

  @override
  State<PlansNotesScreen> createState() => PlansNotesScreenState();
}

class PlansNotesScreenState extends State<PlansNotesScreen> {
  late PlansNotesMode _activeMode;

  @override
  void initState() {
    super.initState();
    _activeMode = widget.mode == PlansNotesMode.overview
        ? PlansNotesMode.plan
        : widget.mode;
  }

  void switchMode(PlansNotesMode mode) {
    if (mode == PlansNotesMode.overview) return;
    setState(() => _activeMode = mode);
  }

  @override
  void didUpdateWidget(PlansNotesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != PlansNotesMode.overview &&
        widget.mode != oldWidget.mode) {
      _activeMode = widget.mode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isPlanMode = _activeMode == PlansNotesMode.plan;

    return AppPage(
      children: [
        _ModeToggle(
          activeMode: _activeMode,
          onChanged: (mode) => setState(() => _activeMode = mode),
        ),
        const SizedBox(height: 16),
        _ModeLeadCard(isPlanMode: isPlanMode),
        const SizedBox(height: 18),
        if (isPlanMode) ...[
          SectionHeader(title: strings.plansSectionTitle),
          _SectionIntro(text: strings.plansSectionSubtitle),
          ...strings.plans.map((plan) => _PlanCard(plan: plan)),
          const SizedBox(height: 24),
          _SecondaryHint(
            label: strings.switchToNotesHint,
            onTap: () => setState(() => _activeMode = PlansNotesMode.note),
          ),
        ] else ...[
          SectionHeader(title: strings.notesSectionTitle),
          _SectionIntro(text: strings.notesSectionSubtitle),
          ...strings.notes.map((note) => _NoteCard(note: note)),
          const SizedBox(height: 24),
          _SecondaryHint(
            label: strings.switchToPlansHint,
            onTap: () => setState(() => _activeMode = PlansNotesMode.plan),
          ),
        ],
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

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.activeMode, required this.onChanged});

  final PlansNotesMode activeMode;
  final ValueChanged<PlansNotesMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isPlan = activeMode == PlansNotesMode.plan;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleChip(
              label: strings.plansSectionTitle,
              active: isPlan,
              onTap: () => onChanged(PlansNotesMode.plan),
            ),
          ),
          Expanded(
            child: _ToggleChip(
              label: strings.notesSectionTitle,
              active: !isPlan,
              onTap: () => onChanged(PlansNotesMode.note),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeLeadCard extends StatelessWidget {
  const _ModeLeadCard({required this.isPlanMode});

  final bool isPlanMode;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPlanMode
                  ? strings.planModeLeadTitle
                  : strings.noteModeLeadTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              isPlanMode
                  ? strings.planModeLeadSubtitle
                  : strings.noteModeLeadSubtitle,
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryHint extends StatelessWidget {
  const _SecondaryHint({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swap_horiz_rounded,
              size: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
