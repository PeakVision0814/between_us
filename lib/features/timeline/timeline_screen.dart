import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/feature_tile.dart';
import '../../shared/widgets/section_header.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      children: [
        SectionHeader(title: 'Timeline'),
        FeatureTile(
          icon: Icons.auto_stories_outlined,
          color: AppTheme.blush,
          title: 'Movie night',
          subtitle: 'Sample local entry for the first prototype.',
        ),
        FeatureTile(
          icon: Icons.local_cafe_outlined,
          color: AppTheme.mint,
          title: 'Sunday walk',
          subtitle: 'Timeline entries will later sync by couple space.',
        ),
      ],
    );
  }
}
