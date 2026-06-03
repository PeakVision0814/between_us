import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import '../../app/app_theme.dart';
import '../../data/models/calendar_event_record.dart';
import '../../shared/widgets/page_visual_language.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime? _selectedDate;
  List<CalendarEventRecord> _events = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedDate ??= _dateOnly(
      AppStrings.of(context).calendarDefaultSelectedDate,
    );
  }

  Future<void> _loadEvents() async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('calendar_events')
          .select()
          .filter('deleted_at', 'is', null)
          .order('starts_at', ascending: true);
      final records = (response as List)
          .map(
            (json) =>
                CalendarEventRecord.fromJson(json as Map<String, dynamic>),
          )
          .toList();
      if (mounted) {
        setState(() {
          _events = records;
        });
      }
    } catch (_) {
      // Supabase not initialized or query failed
    }
  }

  void _refreshEvents() {
    _loadEvents();
  }

  Future<bool> _submitEvent({
    required String title,
    String? description,
    required DateTime startsAt,
    required String eventType,
    required String recurrence,
    bool allDay = false,
  }) async {
    if (title.trim().isEmpty) return false;

    setState(() => _submitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;
      final coupleSpaceId = AppScope.read(context).currentSpaceId;
      if (coupleSpaceId == null) return false;

      await Supabase.instance.client.from('calendar_events').insert({
        'couple_space_id': coupleSpaceId,
        'created_by': user.id,
        'event_type': eventType,
        'title': title.trim(),
        'description': description?.trim(),
        'starts_at': startsAt.toIso8601String(),
        'all_day': allDay,
        'recurrence': recurrence,
      });

      _refreshEvents();
      return true;
    } catch (_) {
      return false;
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayMonth = strings.calendarPrototypeDisplayMonth;
    final visibleDays = strings.calendarVisibleDaysForMonth(displayMonth);

    final entries = _events.map(_recordToEntry).toList();

    final entriesByDay = _groupEntriesByDay(
      entries: entries,
      visibleDays: visibleDays,
    );
    final selectedEntries =
        [
          ...(entriesByDay[_dateKey(_selectedDate!)] ??
              const <CalendarEntryData>[]),
        ]..sort(
          (left, right) => _occurrenceOnDay(
            left,
            _selectedDate!,
          ).compareTo(_occurrenceOnDay(right, _selectedDate!)),
        );
    final upcomingEntries = _getUpcomingEntries(
      entries,
      strings.calendarPrototypeReferenceDate,
    );

    return PageAtmosphere(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Overview card with month grid ──
          PageSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.calendarOverviewTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  strings.calendarOverviewSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppTheme.warmWhite60
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Selected date details ──
          PageSectionHeader(
            title: strings.calendarDetailsTitle,
            subtitle: strings.calendarDetailsHint,
          ),
          const SizedBox(height: 10),
          PageSurfaceCard(
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
                const SizedBox(height: 14),
                if (selectedEntries.isEmpty)
                  _SelectedDayEmptyState(strings: strings, isDark: isDark)
                else
                  ...selectedEntries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SelectedEntryCard(
                        entry: entry,
                        occurrence: _occurrenceOnDay(entry, _selectedDate!),
                        isDark: isDark,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Upcoming events ──
          PageSectionHeader(
            title: strings.calendarUpcomingTitle,
            subtitle: strings.calendarUpcomingHint,
          ),
          const SizedBox(height: 10),
          if (upcomingEntries.isEmpty)
            _UpcomingEmptyState(isChinese: strings.isChinese, isDark: isDark)
          else
            ...upcomingEntries.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _UpcomingEventCard(
                  entry: item.entry,
                  occurrence: item.occurrence,
                  isDark: isDark,
                ),
              ),
            ),
          const SizedBox(height: 24),

          // ── Composer ──
          PageSectionHeader(title: strings.calendarComposerTitle),
          const SizedBox(height: 10),
          _ComposerCard(
            submitting: _submitting,
            onSubmit: _submitEvent,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  CalendarEntryData _recordToEntry(CalendarEventRecord record) {
    return CalendarEntryData(
      id: record.id,
      type: _parseEventType(record.eventType),
      title: record.title,
      description: record.description ?? '',
      startsAt: record.startsAt,
      repeatRule: _parseRecurrence(record.recurrence),
    );
  }

  CalendarEntryType _parseEventType(String type) {
    return switch (type) {
      'anniversary' => CalendarEntryType.anniversary,
      'date_plan' => CalendarEntryType.datePlan,
      'reminder' => CalendarEntryType.reminder,
      _ => CalendarEntryType.reminder,
    };
  }

  CalendarRepeatRule _parseRecurrence(String recurrence) {
    return switch (recurrence) {
      'yearly' => CalendarRepeatRule.yearly,
      _ => CalendarRepeatRule.none,
    };
  }

  List<CalendarEntryOccurrence> _getUpcomingEntries(
    List<CalendarEntryData> entries,
    DateTime reference,
  ) {
    final upcoming = [
      for (final entry in entries)
        if (entry.nextOccurrenceFrom(reference) case final occurrence?)
          CalendarEntryOccurrence(entry: entry, occurrence: occurrence),
    ];
    upcoming.sort((a, b) => a.occurrence.compareTo(b.occurrence));
    return upcoming;
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
        entry.startsAt.hour,
        entry.startsAt.minute,
      );
    }

    return entry.startsAt;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

// ─── Month View ─────────────────────────────────────────────────────────

class _MonthView extends StatelessWidget {
  const _MonthView({
    required this.displayMonth,
    required this.visibleDays,
    required this.selectedDate,
    required this.entriesByDay,
    required this.onSelectDate,
    required this.isDark,
  });

  final DateTime displayMonth;
  final List<DateTime> visibleDays;
  final DateTime selectedDate;
  final Map<String, List<CalendarEntryData>> entriesByDay;
  final ValueChanged<DateTime> onSelectDate;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = AppStrings.of(context);

    return PageInsetPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.formatCalendarMonthYear(displayMonth),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Icon(
                Icons.calendar_today_outlined,
                color: colorScheme.primary,
                size: 20,
              ),
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.warmWhite60
                              : colorScheme.onSurfaceVariant,
                        ),
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
                        isDark: isDark,
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

// ─── Day Cell ───────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.inMonth,
    required this.selected,
    required this.hasEntries,
    required this.onTap,
    required this.isDark,
  });

  final DateTime date;
  final bool inMonth;
  final bool selected;
  final bool hasEntries;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final background = selected
        ? colorScheme.primary
        : (hasEntries
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : colorScheme.primary.withValues(alpha: 0.1))
              : Colors.transparent);
    final borderColor = selected
        ? colorScheme.primary
        : hasEntries
        ? (isDark
              ? Colors.white.withValues(alpha: 0.1)
              : colorScheme.primary.withValues(alpha: 0.22))
        : Colors.transparent;
    final textColor = selected
        ? colorScheme.onPrimary
        : (isDark
              ? (inMonth ? AppTheme.warmWhite90 : AppTheme.warmWhite25)
              : colorScheme.onSurface.withValues(alpha: inMonth ? 1 : 0.4));

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
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: onTap,
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
                              : (isDark
                                    ? AppTheme.heroGlowBlush
                                    : colorScheme.primary))
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

// ─── Selected Entry Card ────────────────────────────────────────────────

class _SelectedEntryCard extends StatelessWidget {
  const _SelectedEntryCard({
    required this.entry,
    required this.occurrence,
    required this.isDark,
  });

  final CalendarEntryData entry;
  final DateTime occurrence;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showsTime = occurrence.hour != 0 || occurrence.minute != 0;

    return PageSurfaceCard(
      variant: PageSurfaceVariant.secondary,
      padding: EdgeInsets.zero,
      child: Padding(
        key: ValueKey('calendar-detail-${entry.id}'),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PageIconBadge(
                  icon: _iconForType(entry.type),
                  color: _colorForType(entry.type),
                  size: 28,
                ),
                const Spacer(),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(label: strings.calendarTypeLabel(entry.type)),
                    _MetaChip(
                      label: strings.calendarRepeatLabel(entry.repeatRule),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              entry.title,
              key: ValueKey('calendar-detail-title-${entry.id}'),
              style: theme.textTheme.titleMedium,
            ),
            if (entry.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                entry.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppTheme.warmWhite60
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              strings.formatCalendarDate(occurrence, includeTime: showsTime),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Selected Day Empty State ────────────────────────────────────────────

class _SelectedDayEmptyState extends StatelessWidget {
  const _SelectedDayEmptyState({required this.strings, required this.isDark});

  final AppStrings strings;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: const ValueKey('calendar-detail-empty'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppTheme.warmGray50.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark
              ? AppTheme.surfaceBorderDarkSoft.withValues(alpha: 0.5)
              : AppTheme.surfaceBorderLightSoft,
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageIconBadge(
            icon: Icons.event_available_outlined,
            color: AppTheme.sage,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.calendarEmptyDayTitle,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  strings.calendarEmptyDaySubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppTheme.warmWhite60
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Upcoming Event Card ────────────────────────────────────────────────

class _UpcomingEventCard extends StatelessWidget {
  const _UpcomingEventCard({
    required this.entry,
    required this.occurrence,
    required this.isDark,
  });

  final CalendarEntryData entry;
  final DateTime occurrence;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showsTime = occurrence.hour != 0 || occurrence.minute != 0;

    return PageSurfaceCard(
      variant: PageSurfaceVariant.secondary,
      padding: EdgeInsets.zero,
      child: Padding(
        key: ValueKey('calendar-upcoming-${entry.id}'),
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageIconBadge(
              icon: _iconForType(entry.type),
              color: _colorForType(entry.type),
              size: 36,
            ),
            const SizedBox(width: 14),
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
                          label: strings.calendarRepeatLabel(
                            entry.repeatRule,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    entry.title,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (entry.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      entry.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppTheme.warmWhite60
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    strings.formatCalendarDate(
                      occurrence,
                      includeWeekday: true,
                      includeTime: showsTime,
                    ),
                    style: theme.textTheme.bodySmall,
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
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Upcoming Empty State ────────────────────────────────────────────────

class _UpcomingEmptyState extends StatelessWidget {
  const _UpcomingEmptyState({required this.isChinese, required this.isDark});

  final bool isChinese;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            PageIconBadge(
              icon: Icons.event_outlined,
              color: AppTheme.gold,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              isChinese ? '还没有日历事件' : 'No calendar events yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isChinese
                  ? '在下方添加纪念日、约会或提醒'
                  : 'Add anniversaries, dates, or reminders below',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppTheme.warmWhite60
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Meta Chip ──────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ─── Entry Chip ─────────────────────────────────────────────────────────

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
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
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

// ─── Composer Card ──────────────────────────────────────────────────────

class _ComposerCard extends StatefulWidget {
  const _ComposerCard({
    required this.submitting,
    required this.onSubmit,
    required this.isDark,
  });

  final bool submitting;
  final Future<bool> Function({
    required String title,
    String? description,
    required DateTime startsAt,
    required String eventType,
    required String recurrence,
    bool allDay,
  })
  onSubmit;
  final bool isDark;

  @override
  State<_ComposerCard> createState() => _ComposerCardState();
}

class _ComposerCardState extends State<_ComposerCard> {
  String _selectedType = 'anniversary';

  void _showCreateDialog() {
    final strings = AppStrings.of(context);
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    bool isAllDay = _selectedType == 'anniversary';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(strings.isChinese ? '新建日历项' : 'Add to calendar'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(
                        strings.calendarTypeLabel(
                          CalendarEntryType.anniversary,
                        ),
                      ),
                      selected: _selectedType == 'anniversary',
                      onSelected: (selected) {
                        if (selected) {
                          setDialogState(() {
                            _selectedType = 'anniversary';
                            isAllDay = true;
                          });
                        }
                      },
                    ),
                    ChoiceChip(
                      label: Text(
                        strings.calendarTypeLabel(CalendarEntryType.datePlan),
                      ),
                      selected: _selectedType == 'date_plan',
                      onSelected: (selected) {
                        if (selected) {
                          setDialogState(() {
                            _selectedType = 'date_plan';
                            isAllDay = false;
                          });
                        }
                      },
                    ),
                    ChoiceChip(
                      label: Text(
                        strings.calendarTypeLabel(CalendarEntryType.reminder),
                      ),
                      selected: _selectedType == 'reminder',
                      onSelected: (selected) {
                        if (selected) {
                          setDialogState(() {
                            _selectedType = 'reminder';
                            isAllDay = false;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: strings.isChinese ? '标题' : 'Title',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    hintText: strings.isChinese
                        ? '描述（可选）'
                        : 'Description (optional)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(strings.isChinese ? '日期' : 'Date'),
                  subtitle: Text(
                    '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                if (!isAllDay)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time),
                    title: Text(strings.isChinese ? '时间' : 'Time'),
                    subtitle: Text(
                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setDialogState(() => selectedTime = picked);
                      }
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings.isChinese ? '取消' : 'Cancel'),
            ),
            FilledButton(
              onPressed: widget.submitting
                  ? null
                  : () async {
                      final startsAt = isAllDay
                          ? DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                            )
                          : DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );

                      final success = await widget.onSubmit(
                        title: titleController.text,
                        description: descriptionController.text.isEmpty
                            ? null
                            : descriptionController.text,
                        startsAt: startsAt,
                        eventType: _selectedType,
                        recurrence: _selectedType == 'anniversary'
                            ? 'yearly'
                            : 'none',
                        allDay: isAllDay,
                      );

                      if (success && context.mounted) {
                        Navigator.pop(context);
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              strings.isChinese
                                  ? '创建失败，请重试'
                                  : 'Failed to create. Please try again.',
                            ),
                          ),
                        );
                      }
                    },
              child: widget.submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(strings.isChinese ? '创建' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isDark = widget.isDark;

    return PageSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.calendarComposerHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppTheme.warmWhite60
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => _selectedType = 'anniversary');
                  _showCreateDialog();
                },
                child: _EntryChip(
                  label: strings.calendarTypeLabel(
                    CalendarEntryType.anniversary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _selectedType = 'date_plan');
                  _showCreateDialog();
                },
                child: _EntryChip(
                  label: strings.calendarTypeLabel(
                    CalendarEntryType.datePlan,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _selectedType = 'reminder');
                  _showCreateDialog();
                },
                child: _EntryChip(
                  label: strings.calendarTypeLabel(
                    CalendarEntryType.reminder,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PageInsetPanel(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageIconBadge(
                  icon: Icons.favorite_outline,
                  color: AppTheme.blush,
                  size: 28,
                ),
                const SizedBox(width: 12),
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.warmWhite60
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────

IconData _iconForType(CalendarEntryType type) {
  return switch (type) {
    CalendarEntryType.anniversary => Icons.favorite_rounded,
    CalendarEntryType.datePlan => Icons.event_available_outlined,
    CalendarEntryType.reminder => Icons.notifications_outlined,
  };
}

Color _colorForType(CalendarEntryType type) {
  return switch (type) {
    CalendarEntryType.anniversary => AppTheme.blush,
    CalendarEntryType.datePlan => AppTheme.gold,
    CalendarEntryType.reminder => AppTheme.sage,
  };
}
