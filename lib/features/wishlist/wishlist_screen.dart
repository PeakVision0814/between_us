import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/feature_tile.dart';
import '../../shared/widgets/section_header.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      children: [
        SectionHeader(title: 'Ideas backlog'),
        FeatureTile(
          icon: Icons.restaurant_menu,
          color: AppTheme.mint,
          title: 'Home menu',
          subtitle:
              'Kept out of the MVP until there is evidence it matters more than the daily note loop.',
        ),
        FeatureTile(
          icon: Icons.redeem_outlined,
          color: AppTheme.blush,
          title: 'Gift ideas',
          subtitle:
              'Worth revisiting later, but not a reason to dilute the first prototype.',
        ),
        FeatureTile(
          icon: Icons.photo_library_outlined,
          color: AppTheme.gold,
          title: 'Photo memories',
          subtitle:
              'A likely follow-up module once the shared habit and privacy model are trusted.',
        ),
      ],
    );
  }
}
