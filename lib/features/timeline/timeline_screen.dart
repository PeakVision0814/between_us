import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/feature_tile.dart';
import '../../shared/widgets/section_header.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      children: [
        const SectionHeader(title: 'Today\'s thread'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prompt: What made today feel close?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'The local prototype keeps this lightweight on purpose: one short note or memory should feel easier than posting anywhere else.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Recent notes'),
        const FeatureTile(
          icon: Icons.auto_stories_outlined,
          color: AppTheme.blush,
          title: 'Mon, May 25 | Movie night',
          subtitle: 'Shared dumplings, one bad thriller, and zero regrets.',
        ),
        const FeatureTile(
          icon: Icons.local_cafe_outlined,
          color: AppTheme.mint,
          title: 'Sun, May 24 | Sunday walk',
          subtitle:
              'Stopped for coffee after the river path and talked about June plans.',
        ),
        const FeatureTile(
          icon: Icons.favorite_outline,
          color: AppTheme.gold,
          title: 'Why it matters',
          subtitle:
              'This tab is the MVP habit loop: leave one note, revisit one memory, come back tomorrow.',
        ),
      ],
    );
  }
}
