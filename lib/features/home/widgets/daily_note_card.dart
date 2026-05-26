import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../app/app_strings.dart';

class DailyNoteCard extends StatelessWidget {
  const DailyNoteCard({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.sticky_note_2_outlined, color: AppTheme.blush),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.actionCardTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(strings.actionCardHint),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.blush.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(strings.actionCardExample),
            ),
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: onPressed,
              icon: const Icon(Icons.edit_note),
              label: Text(strings.leaveOneLineLabel),
            ),
          ],
        ),
      ),
    );
  }
}
