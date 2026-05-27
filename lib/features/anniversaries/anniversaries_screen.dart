import 'package:flutter/material.dart';

import '../../app/app_strings.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/section_header.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime? _selectedDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedDate ??= _dateOnly(AppStrings.of(context).calendarDefaultSelectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final displayMonth = strings.calendarPrototypeDisplayMonth;
    final visibleDays = strings.calendarVisibleDaysForMonth(displayMonth);
    final entriesByDay = _groupEntriesByDay(
      entries: strings.calendarPrototypeEntries,
      visibleDays: visibleDays,
    );
    final selectedEntries = [
      ...(entriesByDay[_dateKey(_selectedDate!)] ?? const <CalendarEntryData>[]),
    ]..sort(
        (left, right) => _occurrenceOnDay(
          left,
          _selectedDate!,
        ).compareTo(_occurrenceOnDay(right, _selectedDate!)),
      );
    final upcomingEntries = strings.calendarUpcomingEntries;

    return AppPage(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.calendarOverviewTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(strings.calendarOverviewSubtitle),
                const SizedBox(height: 6),
                Text(
                  strings.calendarOverviewCaption,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 18),
                _MonthView(
                  displayMonth: displayMonth,
                  visibleDays: visibleDays,
                  selectedDate: _selectedDate!,
                  entriesByDay: entriesByDay,
                  onSelectDate: (day) {
                    setState(() {
                      _selectedDate = _dateOnly(day);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader(title: strings.calendarDetailsTitle),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.formatCalendarDate(
                    _selectedDate!,
                    includeWeekday: true,
                  ),
                  key: const ValueKey('calendar-selected-date-label'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  strings.calendarDetailsHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                if (selectedEntries.isEmpty)
                  _SelectedDayEmptyState(strings: strings)
                else
                  ...selectedEntries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SelectedEntryCard(
                        entry: entry,
                        occurrence: _occurrenceOnDay(entry, _selectedDate!),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader(title: strings.calendarUpcomingTitle),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            strings.calendarUpcomingHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        ...upcomingEntries.map(
          (item) => _UpcomingEventCard(
            entry: item.entry,
            occurrence: item.occurrence,
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader(title: strings.calendarComposerTitle),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.calendarComposerHint),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _EntryChip(
                      label: strings.calendarTypeLabel(
                        CalendarEntryType.anniversary,
                      ),
                    ),
                    _EntryChip(
                      label: strings.calendarTypeLabel(CalendarEntryType.date),
                    ),
                    _EntryChip(
                      label: strings.calendarTypeLabel(
                        CalendarEntryType.reminder,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.favorite_outline,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.calendarPeriodPlaceholderTitle,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              strings.calendarPeriodPlaceholderSubtitle,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<String, List<CalendarEntryData>> _groupEntriesByDay({
    required List<CalendarEntryData> entries,
    required List<DateTime> visibleDays,
  }) {
    final grouped = <String, List<CalendarEntryData>>{};

    for (final day in visibleDays) {
      final items = entries.where((entry) => entry.occursOn(day)).toList();
      if (items.isNotEmpty) {
        grouped[_dateKey(day)] = items;
      }
    }

    return grouped;
  }

  static DateTime _occurrenceOnDay(CalendarEntryData entry, DateTime day) {
    if (entry.repeatRule == CalendarRepeatRule.yearly) {
      return DateTime(
        day.year,
        day.month,
        day.day,
        entry.date.hour,
        entry.date.minute,
      );
    }

    return entry.date;
  }

  static DateTime _dateOnly(DateTime date) => DateTime(
    date.year,
    date.month,
    date.day,
  );

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class _MonthView extends StatelessWidget {
  const _MonthView({
    required this.displayMonth,
    required this.visibleDays,
    required this.selectedDate,
    required this.entriesByDay,
    required this.onSelectDate,
  });

  final DateTime displayMonth;
  final List<DateTime> visibleDays;
  final DateTime selectedDate;
  final Map<String, List<CalendarEntryData>> entriesByDay;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = AppStrings.of(context);

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
              Text(
                strings.formatCalendarMonthYear(displayMonth),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Icon(Icons.calendar_today_outlined, color: colorScheme.primary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: strings.weekLabels
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
          for (var index = 0; index < visibleDays.length; index += 7)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  for (final day in visibleDays.sublist(index, index + 7))
                    Expanded(
                      child: _DayCell(
                        date: day,
                        inMonth: day.month == displayMonth.month,
                        selected: _sameDate(day, selectedDate),
                        hasEntries: entriesByDay.containsKey(_dateKey(day)),
                        onTap: () => onSelectDate(day),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static bool _sameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.inMonth,
    required this.selected,
    required this.hasEntries,
    required this.onTap,
  });

  final DateTime date;
  final bool inMonth;
  final bool selected;
  final bool hasEntries;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = selected
        ? colorScheme.primary
        : (hasEntries
              ? colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent);
    final borderColor = selected
        ? colorScheme.primary
        : hasEntries
        ? colorScheme.primary.withValues(alpha: 0.28)
        : Colors.transparent;
    final textColor = selected
        ? colorScheme.onPrimary
        : colorScheme.onSurface.withValues(alpha: inMonth ? 1 : 0.45);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey(
            'calendar-day-${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}',
          ),
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: selected || hasEntries
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: hasEntries
                        ? (selected
                              ? colorScheme.onPrimary
                              : colorScheme.primary)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedEntryCard extends StatelessWidget {
  const _SelectedEntryCard({
    required this.entry,
    required this.occurrence,
  });

  final CalendarEntryData entry;
  final DateTime occurrence;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final showsTime = occurrence.hour != 0 || occurrence.minute != 0;

    return Container(
      key: ValueKey('calendar-detail-${entry.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: strings.calendarTypeLabel(entry.type)),
              _MetaChip(label: strings.calendarRepeatLabel(entry.repeatRule)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            entry.title,
            key: ValueKey('calendar-detail-title-${entry.id}'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(entry.subtitle),
          const SizedBox(height: 10),
          Text(
            strings.formatCalendarDate(
              occurrence,
              includeTime: showsTime,
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SelectedDayEmptyState extends StatelessWidget {
  const _SelectedDayEmptyState({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      key: const ValueKey('calendar-detail-empty'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.calendarEmptyDayTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            strings.calendarEmptyDaySubtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _UpcomingEventCard extends StatelessWidget {
  const _UpcomingEventCard({
    required this.entry,
    required this.occurrence,
  });

  final CalendarEntryData entry;
  final DateTime occurrence;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final showsTime = occurrence.hour != 0 || occurrence.minute != 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        key: ValueKey('calendar-upcoming-${entry.id}'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(label: strings.calendarTypeLabel(entry.type)),
                        if (entry.repeatRule == CalendarRepeatRule.yearly)
                          _MetaChip(
                            label: strings.calendarRepeatLabel(entry.repeatRule),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      entry.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(entry.subtitle),
                    const SizedBox(height: 10),
                    Text(
                      strings.formatCalendarDate(
                        occurrence,
                        includeWeekday: true,
                        includeTime: showsTime,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                strings.formatCountdownLabel(
                  occurrence,
                  strings.calendarPrototypeReferenceDate,
                ),
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
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
