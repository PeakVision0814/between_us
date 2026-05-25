import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/feature_tile.dart';
import '../../shared/widgets/section_header.dart';

class AnniversariesScreen extends StatelessWidget {
  const AnniversariesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      children: [
        SectionHeader(title: 'Anniversaries'),
        FeatureTile(
          icon: Icons.favorite_outline,
          color: AppTheme.berry,
          title: 'Relationship start',
          subtitle: 'Create countdowns and yearly reminders.',
        ),
        FeatureTile(
          icon: Icons.celebration_outlined,
          color: AppTheme.gold,
          title: 'Special days',
          subtitle: 'Birthdays, first trips, and private rituals.',
        ),
      ],
    );
  }
}
