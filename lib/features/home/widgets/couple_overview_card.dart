import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../shared/widgets/circle_badge.dart';

class CoupleOverviewCard extends StatelessWidget {
  const CoupleOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleBadge(label: 'A', color: AppTheme.blush),
                const SizedBox(width: 8),
                const CircleBadge(label: 'B', color: AppTheme.mint),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.berry.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'private beta',
                    style: TextStyle(
                      color: AppTheme.berry,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Our shared room',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'Supabase auth and couple-space sync will connect this card to real private data in Phase 3.',
            ),
          ],
        ),
      ),
    );
  }
}
