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
  late DateTime _displayMonth;
  List<CalendarEventRecord> _events = [];
  bool _submitting = false;
  bool _eventsLoaded = false;

  @visibleForTesting
  void debugSetEvents(List<CalendarEventRecord> events) {
    setState(() {
      _events = events;
      _eventsLoaded = true;
    });
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
    _selectedDate = _dateOnly(now);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.of(context);
    if (!_eventsLoaded && controller.hasActiveCoupleSpace) {
      _eventsLoaded = true;
      _loadEvents();
    }
  }

  Future<void> _loadEvents() async {
    try {
      final response = await Supabase.instance.client
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
      // Supabase not initialized or query failed.
    }
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
    if (!AppScope.read(context).hasActiveCoupleSpace) return false;

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

      await _loadEvents();
      return true;
    } catch (_) {
      return false;
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    if (!AppScope.read(context).hasActiveCoupleSpace) return;
    final coupleSpaceId = AppScope.read(context).currentSpaceId;
    if (coupleSpaceId == null) return;

    try {
      await Supabase.instance.client
          .from('calendar_events')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', eventId)
          .eq('couple_space_id', coupleSpaceId)
          .filter('deleted_at', 'is', null);

      await _loadEvents();
    } catch (_) {
      if (mounted) {
        final strings = AppStrings.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.calendarDeleteFailedError)),
        );
      }
    }
  }

  void _confirmDeleteEvent(String eventId, String title) {
    final strings = AppStrings.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.calendarDeleteConfirmTitle),
        content: Text(strings.calendarDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.profileCancelLabel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteEvent(eventId);
            },
            child: Text(strings.calendarDeleteButton),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    final strings = AppStrings.of(context);
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = _selectedDate ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    String selectedType = 'date_plan';
    bool isAllDay = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(strings.calendarCreateDialogTitle),
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
                        strings.calendarTypeLabel(CalendarEntryType.datePlan),
                      ),
                      selected: selectedType == 'date_plan',
                      onSelected: (selected) {
                        if (selected) {
                          setDialogState(() {
                            selectedType = 'date_plan';
                            isAllDay = false;
                          });
                        }
                      },
                    ),
                    ChoiceChip(
                      label: Text(
                        strings.calendarTypeLabel(CalendarEntryType.reminder),
                      ),
                      selected: selectedType == 'reminder',
                      onSelected: (selected) {
                        if (selected) {
                          setDialogState(() {
                            selectedType = 'reminder';
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
                    hintText: strings.calendarTitleHint,
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    hintText: strings.calendarDescriptionHint,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(strings.calendarDateLabel),
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
                    title: Text(strings.calendarTimeLabel),
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
              child: Text(strings.profileCancelLabel),
            ),
            FilledButton(
              onPressed: _submitting
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

                      final success = await _submitEvent(
                        title: titleController.text,
                        description: descriptionController.text.isEmpty
                            ? null
                            : descriptionController.text,
                        startsAt: startsAt,
                        eventType: selectedType,
                        recurrence: 'none',
                        allDay: isAllDay,
                      );

                      if (success && context.mounted) {
                        Navigator.pop(context);
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(strings.calendarCreateFailedError),
                          ),
                        );
                      }
                    },
              child: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(strings.calendarCreateButton),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPaired = AppScope.of(context).hasActiveCoupleSpace;

    if (!isPaired) {
      return PageAtmosphere(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageSectionHeader(title: strings.calendarTab),
            const SizedBox(height: 12),
            _CalendarPendingEmptyState(strings: strings),
          ],
        ),
      );
    }

    final visibleDays = strings.calendarVisibleDaysForMonth(_displayMonth);
    final now = DateTime.now();

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
    final upcomingEntries = _getUpcomingEntries(entries, now);

    return PageAtmosphere(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Month grid ──
          PageSurfaceCard(
            child: _MonthView(
              displayMonth: _displayMonth,
              visibleDays: visibleDays,
              selectedDate: _selectedDate!,
              entriesByDay: entriesByDay,
              onSelectDate: (day) {
                setState(() {
                  _selectedDate = _dateOnly(day);
                });
              },
              onAddEvent: _showCreateDialog,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 24),

          // ── Selected date details ──
          PageSectionHeader(
            title: strings.calendarDetailsTitle,
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
                        onDelete: () =>
                            _confirmDeleteEvent(entry.id, entry.title),
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
          ),
          const SizedBox(height: 10),
          if (upcomingEntries.isEmpty)
            _UpcomingEmptyState(strings: strings, isDark: isDark)
          else
            ...upcomingEntries.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _UpcomingEventCard(
                  entry: item.entry,
                  occurrence: item.occurrence,
                  isDark: isDark,
                  onDelete: () =>
                      _confirmDeleteEvent(item.entry.id, item.entry.title),
                ),
              ),
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
    this.onAddEvent,
  });

  final DateTime displayMonth;
  final List<DateTime> visibleDays;
  final DateTime selectedDate;
  final Map<String, List<CalendarEntryData>> entriesByDay;
  final ValueChanged<DateTime> onSelectDate;
  final bool isDark;
  final VoidCallback? onAddEvent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = AppStrings.of(context);

    return PageInsetPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.formatCalendarMonthYear(displayMonth),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (onAddEvent != null)
                IconButton(
                  onPressed: onAddEvent,
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: strings.createCalendarEntrySection,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
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
    this.onDelete,
  });

  final CalendarEntryData entry;
  final DateTime occurrence;
  final bool isDark;
  final VoidCallback? onDelete;

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
                if (onDelete != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: strings.calendarDeleteButton,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
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
                  strings.calendarSelectedDayEmpty,
                  style: theme.textTheme.titleSmall,
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
    this.onDelete,
  });

  final CalendarEntryData entry;
  final DateTime occurrence;
  final bool isDark;
  final VoidCallback? onDelete;

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
                          label: strings.calendarRepeatLabel(entry.repeatRule),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(entry.title, style: theme.textTheme.titleMedium),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  strings.formatCountdownLabel(occurrence, DateTime.now()),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
                if (onDelete != null) ...[
                  const SizedBox(height: 4),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: strings.calendarDeleteButton,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Calendar Pending Empty State ──────────────────────────────────────

class _CalendarPendingEmptyState extends StatelessWidget {
  const _CalendarPendingEmptyState({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            PageIconBadge(
              icon: Icons.calendar_month_outlined,
              color: AppTheme.gold,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(strings.calendarNoEventsYet, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              strings.invitePartnerToStartUsing,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppTheme.warmWhite60
                    : colorScheme.onSurfaceVariant,
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
  const _UpcomingEmptyState({required this.strings, required this.isDark});

  final AppStrings strings;
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
            Text(strings.calendarNoEventsYet, style: theme.textTheme.titleMedium),
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
