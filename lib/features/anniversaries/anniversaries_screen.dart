import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/feature_tile.dart';
import '../../shared/widgets/section_header.dart';

class AnniversariesScreen extends StatelessWidget {
  const AnniversariesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      children: [
        const SectionHeader(title: 'Next important date'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Relationship start anniversary',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      const Text('June 6 | yearly reminder'),
                    ],
                  ),
                ),
                Text(
                  '12\ndays',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.berry,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Saved dates'),
        const FeatureTile(
          icon: Icons.favorite_outline,
          color: AppTheme.berry,
          title: 'Relationship start',
          subtitle:
              'The anchor date for yearly countdowns and shared reminders.',
        ),
        const FeatureTile(
          icon: Icons.celebration_outlined,
          color: AppTheme.gold,
          title: 'Special days',
          subtitle:
              'Birthdays, first trips, and private rituals can stay small but visible.',
        ),
        const FeatureTile(
          icon: Icons.add_alert_outlined,
          color: AppTheme.mint,
          title: 'Why it matters',
          subtitle:
              'Dates earn a primary tab only because they reinforce the daily shared loop instead of acting like a buried utility.',
        ),
      ],
    );
  }
}
