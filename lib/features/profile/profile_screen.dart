import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/feature_tile.dart';
import '../../shared/widgets/section_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      children: [
        SectionHeader(title: 'Profile'),
        FeatureTile(
          icon: Icons.lock_outline,
          color: AppTheme.berry,
          title: 'Private by default',
          subtitle:
              'No public profiles, feeds, or analytics-first product choices.',
        ),
        FeatureTile(
          icon: Icons.cloud_outlined,
          color: AppTheme.mint,
          title: 'Supabase pending',
          subtitle:
              'Auth, RLS, storage, and sync will be added after the local prototype.',
        ),
      ],
    );
  }
}
