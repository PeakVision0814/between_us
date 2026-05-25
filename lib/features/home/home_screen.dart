import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/feature_tile.dart';
import '../../shared/widgets/section_header.dart';
import 'widgets/couple_overview_card.dart';
import 'widgets/daily_note_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onWriteTodayNote,
    required this.onReviewDates,
    required this.onOpenBacklog,
    required this.onOpenSettings,
  });

  final VoidCallback onWriteTodayNote;
  final VoidCallback onReviewDates;
  final VoidCallback onOpenBacklog;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      children: [
        Text('Between Us', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'One quiet place for today\'s note and the dates you both care about.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        CoupleOverviewCard(onOpenSettings: onOpenSettings),
        const SizedBox(height: 14),
        DailyNoteCard(onPressed: onWriteTodayNote),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onWriteTodayNote,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Write today\'s note'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReviewDates,
                icon: const Icon(Icons.event_outlined),
                label: const Text('Review dates'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const SectionHeader(title: 'Why this MVP'),
        const FeatureTile(
          icon: Icons.auto_stories_outlined,
          color: AppTheme.blush,
          title: 'Daily note first',
          subtitle:
              'A short shared message is the clearest reason to open the app again tomorrow.',
        ),
        const FeatureTile(
          icon: Icons.event_available,
          color: AppTheme.gold,
          title: 'Dates stay visible',
          subtitle:
              'Important milestones stay close at hand instead of getting buried in a settings page.',
        ),
        const SizedBox(height: 8),
        const SectionHeader(title: 'Secondary pages'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: onOpenBacklog,
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('Ideas backlog'),
            ),
            OutlinedButton.icon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.shield_outlined),
              label: const Text('Space settings'),
            ),
          ],
        ),
      ],
    );
  }
}
