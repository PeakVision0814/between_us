import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

class DailyNoteCard extends StatelessWidget {
  const DailyNoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.sticky_note_2_outlined, color: AppTheme.blush),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily note',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'A lightweight message area will land here before backend sync.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
