import 'package:flutter/material.dart';

import '../../app/app_strings.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/section_header.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final items = strings.calendarItems;

    return AppPage(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.calendarLeadTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(strings.calendarLeadSubtitle),
                const SizedBox(height: 18),
                _MonthViewPlaceholder(isChinese: strings.isChinese),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader(title: strings.selectedDateSection),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.selectedDateLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...items.take(2).map((item) => _SelectedDateRow(item: item)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader(title: strings.upcomingEventsSection),
        ...items.map((item) => _UpcomingEventCard(item: item)),
        const SizedBox(height: 18),
        SectionHeader(title: strings.createCalendarEntrySection),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _EntryChip(label: strings.createAnniversaryLabel),
                    _EntryChip(label: strings.createDatePlanLabel),
                    _EntryChip(label: strings.createReminderLabel),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  strings.periodPlaceholderLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthViewPlaceholder extends StatelessWidget {
  const _MonthViewPlaceholder({required this.isChinese});

  final bool isChinese;
  static const _rows = [
    [26, 27, 28, 29, 30, 31, 1],
    [2, 3, 4, 5, 6, 7, 8],
    [9, 10, 11, 12, 13, 14, 15],
    [16, 17, 18, 19, 20, 21, 22],
    [23, 24, 25, 26, 27, 28, 29],
    [30, 1, 2, 3, 4, 5, 6],
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final weekLabels = isChinese
        ? const ['一', '二', '三', '四', '五', '六', '日']
        : const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final monthLabel = isChinese ? '2026 年 6 月' : 'June 2026';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(monthLabel, style: Theme.of(context).textTheme.titleMedium),
              Icon(Icons.expand_more, color: colorScheme.primary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: weekLabels
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          ..._rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: row
                    .map(
                      (day) => Expanded(
                        child: _DayCell(
                          label: '$day',
                          selected: day == 6,
                          marked: day == 6 || day == 25 || day == 29,
                          faded: day > 29,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.label,
    required this.selected,
    required this.marked,
    required this.faded,
  });

  final String label;
  final bool selected;
  final bool marked;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = selected
        ? colorScheme.primary
        : (marked
              ? colorScheme.tertiary.withValues(alpha: 0.18)
              : Colors.transparent);
    final textColor = selected ? colorScheme.onPrimary : colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: faded ? textColor.withValues(alpha: 0.35) : textColor,
              fontWeight: selected || marked
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedDateRow extends StatelessWidget {
  const _SelectedDateRow({required this.item});

  final CalendarItemCopy item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 10),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(item.subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingEventCard extends StatelessWidget {
  const _UpcomingEventCard({required this.item});

  final CalendarItemCopy item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(item.subtitle),
                    const SizedBox(height: 10),
                    Text(
                      item.dateLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                item.countdownLabel,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryChip extends StatelessWidget {
  const _EntryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
