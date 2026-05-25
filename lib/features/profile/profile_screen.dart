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
        SectionHeader(title: 'Space settings'),
        FeatureTile(
          icon: Icons.group_outlined,
          color: AppTheme.mint,
          title: 'Invite and ownership',
          subtitle:
              'One person creates the couple space, one invite brings the second person in, and active membership must stop at two people.',
        ),
        FeatureTile(
          icon: Icons.lock_outline,
          color: AppTheme.berry,
          title: 'Private by default',
          subtitle:
              'No public profiles, feeds, or preview-heavy notifications until both people explicitly allow them.',
        ),
        FeatureTile(
          icon: Icons.delete_outline,
          color: AppTheme.gold,
          title: 'Unlink and delete',
          subtitle:
              'Unlink, export, and permanent deletion rules are design work that must be settled before backend launch.',
        ),
      ],
    );
  }
}
