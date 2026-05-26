import 'package:flutter/material.dart';

import '../../../app/app_strings.dart';
import '../../../app/app_theme.dart';
import '../../../shared/widgets/circle_badge.dart';

class CoupleOverviewCard extends StatelessWidget {
  const CoupleOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleBadge(label: '满', color: AppTheme.blush),
                const SizedBox(width: 10),
                const CircleBadge(label: '澈', color: AppTheme.mint),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    strings.relationshipStatus,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              strings.coupleNames,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(strings.relationshipMood),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatusPill(
                    icon: Icons.home_work_outlined,
                    label: strings.spaceStatusLabel,
                    value: strings.spaceStatusValue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatusPill(
                    icon: Icons.favorite_outline,
                    label: strings.overviewChipOne,
                    value: strings.overviewChipTwo,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
