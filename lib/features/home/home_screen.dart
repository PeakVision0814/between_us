import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/feature_tile.dart';
import '../../shared/widgets/section_header.dart';
import 'widgets/couple_overview_card.dart';
import 'widgets/daily_note_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      children: [
        Text('Between Us', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'A calm private space for memories, plans, and small everyday rituals.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        const CoupleOverviewCard(),
        const SizedBox(height: 14),
        const DailyNoteCard(),
        const SizedBox(height: 14),
        const SectionHeader(title: 'Next up'),
        const FeatureTile(
          icon: Icons.event_available,
          color: AppTheme.gold,
          title: 'First anniversary',
          subtitle: 'Add the relationship start date and show countdowns here.',
        ),
      ],
    );
  }
}
