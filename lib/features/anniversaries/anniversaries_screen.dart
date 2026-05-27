import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_strings.dart';
import '../../data/models/calendar_event_record.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/section_header.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime? _selectedDate;
  List<CalendarEventRecord> _events = [];
  String? _coupleSpaceId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadCoupleSpaceId();
    _loadEvents();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedDate ??= _dateOnly(AppStrings.of(context).calendarDefaultSelectedDate);
  }

  Future<void> _loadCoupleSpaceId() async {
    try {
      final response = await Supabase.instance.client
          .from('couple_spaces')
          .select('id')
          .limit(1)
          .maybeSingle();
      if (response != null) {
        _coupleSpaceId = response['id'] as String;
      }
    } catch (_) {
      // Supabase not initialized or query failed
      _coupleSpaceId = null;
    }
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
          .map((json) => CalendarEventRecord.fromJson(json as Map<String, dynamic>))
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
    if (_coupleSpaceId == null || title.trim().isEmpty) return false;

    setState(() => _submitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;

      await Supabase.instance.client.from('calendar_events').insert({
        'couple_space_id': _coupleSpaceId,
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
    final displayMonth = strings.calendarPrototypeDisplayMonth;
    final visibleDays = strings.calendarVisibleDaysForMonth(displayMonth);

    final entries = _events.map(_recordToEntry).toList();

    final entriesByDay = _groupEntriesByDay(
      entries: entries,
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
    final upcomingEntries = _getUpcomingEntries(entries, strings.calendarPrototypeReferenceDate);

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
        if (upcomingEntries.isEmpty)
          _UpcomingEmptyState(isChinese: strings.isChinese)
        else
          ...upcomingEntries.map(
            (item) => _UpcomingEventCard(
              entry: item.entry,
              occurrence: item.occurrence,
            ),
          ),
        const SizedBox(height: 18),
        SectionHeader(title: strings.calendarComposerTitle),
        _ComposerCard(
          submitting: _submitting,
          onSubmit: _submitEvent,
        ),
      ],
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
          Text(entry.description),
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
                    Text(entry.description),
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

class _UpcomingEmptyState extends StatelessWidget {
  const _UpcomingEmptyState({required this.isChinese});

  final bool isChinese;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.event_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              isChinese ? '还没有日历事件' : 'No calendar events yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isChinese
                  ? '在下方添加纪念日、约会或提醒'
                  : 'Add anniversaries, dates, or reminders below',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerCard extends StatefulWidget {
  const _ComposerCard({
    required this.submitting,
    required this.onSubmit,
  });

  final bool submitting;
  final Future<bool> Function({
    required String title,
    String? description,
    required DateTime startsAt,
    required String eventType,
    required String recurrence,
    bool allDay,
  }) onSubmit;

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
                      label: Text(strings.calendarTypeLabel(CalendarEntryType.anniversary)),
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
                      label: Text(strings.calendarTypeLabel(CalendarEntryType.datePlan)),
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
                      label: Text(strings.calendarTypeLabel(CalendarEntryType.reminder)),
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
                    hintText: strings.isChinese ? '描述（可选）' : 'Description (optional)',
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
                          ? DateTime(selectedDate.year, selectedDate.month, selectedDate.day)
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
                        recurrence: _selectedType == 'anniversary' ? 'yearly' : 'none',
                        allDay: isAllDay,
                      );

                      if (success && context.mounted) {
                        Navigator.pop(context);
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(strings.isChinese
                                ? '创建失败，请重试'
                                : 'Failed to create. Please try again.'),
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

    return Card(
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
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedType = 'anniversary');
                    _showCreateDialog();
                  },
                  child: _EntryChip(
                    label: strings.calendarTypeLabel(CalendarEntryType.anniversary),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedType = 'date_plan');
                    _showCreateDialog();
                  },
                  child: _EntryChip(
                    label: strings.calendarTypeLabel(CalendarEntryType.datePlan),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedType = 'reminder');
                    _showCreateDialog();
                  },
                  child: _EntryChip(
                    label: strings.calendarTypeLabel(CalendarEntryType.reminder),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
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
    );
  }
}
