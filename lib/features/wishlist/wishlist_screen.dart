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
        SectionHeader(title: 'Wishlist'),
        FeatureTile(
          icon: Icons.restaurant_menu,
          color: AppTheme.mint,
          title: 'Home menu',
          subtitle: 'A later module for shared food requests and status.',
        ),
        FeatureTile(
          icon: Icons.redeem_outlined,
          color: AppTheme.blush,
          title: 'Gift ideas',
          subtitle: 'Keep small wishes in one private place.',
        ),
      ],
    );
  }
}
