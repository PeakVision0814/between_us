import 'package:flutter/material.dart';

import '../../app/app_strings.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/section_header.dart';
import 'widgets/couple_overview_card.dart';
import 'widgets/daily_note_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onLeaveOneLine,
    required this.onReviewDates,
    required this.onOpenMoments,
    required this.onOpenSettings,
  });

  final VoidCallback onLeaveOneLine;
  final VoidCallback onReviewDates;
  final VoidCallback onOpenMoments;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final moment = strings.moments.first;
    final nextDate = strings.dates.first;

    return AppPage(
      children: [
        Text(
          strings.homeGreeting,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          strings.homeSubtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        const CoupleOverviewCard(),
        const SizedBox(height: 14),
        DailyNoteCard(onPressed: onLeaveOneLine),
        const SizedBox(height: 14),
        SectionHeader(title: strings.recentMomentSection),
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onOpenMoments,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${moment.author} | ${moment.timeLabel}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    moment.text,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader(title: strings.nextDateSection),
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onReviewDates,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nextDate.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(nextDate.subtitle),
                        const SizedBox(height: 10),
                        Text(
                          nextDate.dateLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    nextDate.countdownLabel,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader(title: strings.quickLinksSection),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ActionChip(
              avatar: const Icon(Icons.auto_awesome_outlined, size: 18),
              label: Text(strings.openMomentsLabel),
              onPressed: onOpenMoments,
            ),
            ActionChip(
              avatar: const Icon(Icons.event_note_outlined, size: 18),
              label: Text(strings.openDatesLabel),
              onPressed: onReviewDates,
            ),
            ActionChip(
              avatar: const Icon(Icons.settings_outlined, size: 18),
              label: Text(strings.openSettingsLabel),
              onPressed: onOpenSettings,
            ),
          ],
        ),
      ],
    );
  }
}
