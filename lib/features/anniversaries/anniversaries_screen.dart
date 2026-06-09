import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import '../../app/app_theme.dart';
import '../../data/models/calendar_event_record.dart';
import '../../data/models/cycle_record.dart';
import '../../shared/widgets/page_visual_language.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const double _calendarCollapseScrollOffset = 36;
  static const double _calendarExpandScrollOffset = 8;
  static const double _calendarExpandDragDelta = -20;

  DateTime? _selectedDate;
  late DateTime _displayMonth;
  List<CalendarEventRecord> _events = [];
  List<CycleRecord> _cycleRecords = [];
  Map<String, String> _eventCreators = {};
  bool _submitting = false;
  bool _eventsLoaded = false;
  bool _loadingEvents = false;
  bool _reloadAfterCurrentLoad = false;
  DateTime? _lastLoadTime;
  CalendarFilter _activeFilter = CalendarFilter.all;
  bool _calendarExpanded = true;

  @visibleForTesting
  void debugSetEvents(List<CalendarEventRecord> events) {
    setState(() {
      _events = events;
      _eventCreators = {for (final e in events) e.id: e.createdBy};
      _eventsLoaded = true;
    });
  }

  @visibleForTesting
  void debugSetCycleRecords(List<CycleRecord> records) {
    setState(() {
      _cycleRecords = records;
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

  void _previousMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
      _selectedDate = _dateOnly(_displayMonth);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
      _selectedDate = _dateOnly(_displayMonth);
    });
  }

  void _selectCalendarDay(DateTime day) {
    final normalized = _dateOnly(day);
    setState(() {
      _selectedDate = normalized;
      if (_displayMonth.year != normalized.year ||
          _displayMonth.month != normalized.month) {
        _displayMonth = DateTime(normalized.year, normalized.month);
      }
    });
  }

  void _setCalendarExpanded(bool expanded) {
    if (_calendarExpanded == expanded || !mounted) return;
    setState(() => _calendarExpanded = expanded);
  }

  bool _handleCalendarScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }

    final pixels = notification.metrics.pixels;
    if (pixels <= _calendarExpandScrollOffset) {
      _setCalendarExpanded(true);
      return false;
    }

    if (_calendarExpanded && pixels >= _calendarCollapseScrollOffset) {
      _setCalendarExpanded(false);
      return false;
    }

    if (!_calendarExpanded &&
        notification is ScrollUpdateNotification &&
        (notification.scrollDelta ?? 0) <= _calendarExpandDragDelta &&
        pixels <= _calendarCollapseScrollOffset) {
      _setCalendarExpanded(true);
    }

    return false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.of(context);
    controller.addListener(_onControllerChanged);
    if (!_eventsLoaded && controller.hasActiveCoupleSpace) {
      _eventsLoaded = true;
      _loadEvents();
    }
  }

  @override
  void dispose() {
    try {
      final controller = AppScope.read(context);
      controller.removeListener(_onControllerChanged);
    } catch (_) {}
    super.dispose();
  }

  void _onControllerChanged() {
    _loadEvents(force: true);
  }

  Future<void> _onRefresh() async {
    final controller = AppScope.read(context);
    await controller.refreshAllData();
    await _loadEvents(force: true);
  }

  Future<void> _loadEvents({bool force = false}) async {
    if (!force &&
        _lastLoadTime != null &&
        DateTime.now().difference(_lastLoadTime!).inMinutes < 5) {
      return;
    }
    if (_loadingEvents) {
      if (force) _reloadAfterCurrentLoad = true;
      return;
    }
    _loadingEvents = true;

    try {
      final controller = AppScope.read(context);
      final coupleSpaceId = controller.currentSpaceId;
      if (!controller.hasActiveCoupleSpace || coupleSpaceId == null) {
        if (mounted) {
          setState(() {
            _events = [];
            _cycleRecords = [];
            _eventCreators = {};
          });
        }
        _lastLoadTime = DateTime.now();
        return;
      }

      final response = await Supabase.instance.client
          .from('calendar_events')
          .select()
          .eq('couple_space_id', coupleSpaceId)
          .isFilter('deleted_at', null)
          .order('starts_at', ascending: true);
      final records = (response as List)
          .map(
            (json) =>
                CalendarEventRecord.fromJson(json as Map<String, dynamic>),
          )
          .toList();
      final cycleResponse = await Supabase.instance.client
          .from('cycle_records')
          .select()
          .eq('couple_space_id', coupleSpaceId)
          .isFilter('deleted_at', null)
          .order('period_start_date', ascending: true);
      final cycleRecords = (cycleResponse as List)
          .map((json) => CycleRecord.fromJson(json as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _events = records;
          _cycleRecords = cycleRecords;
          _eventCreators = {for (final e in records) e.id: e.createdBy};
        });
      }
      _lastLoadTime = DateTime.now();
    } catch (e) {
      debugPrint('[Calendar] loadEvents failed: $e');
    } finally {
      _loadingEvents = false;
      if (_reloadAfterCurrentLoad) {
        _reloadAfterCurrentLoad = false;
        await _loadEvents(force: true);
      }
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

      final inserted = await Supabase.instance.client
          .from('calendar_events')
          .insert({
            'couple_space_id': coupleSpaceId,
            'created_by': user.id,
            'event_type': eventType,
            'title': title.trim(),
            'description': description?.trim(),
            'starts_at': startsAt.toIso8601String(),
            'all_day': allDay,
            'recurrence': recurrence,
          })
          .select()
          .single();

      if (mounted) {
        _upsertEventLocally(CalendarEventRecord.fromJson(inserted));
      }
      await _loadEvents(force: true);
      return true;
    } catch (e) {
      debugPrint('[Calendar] submitEvent failed: $e');
      return false;
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<bool> _submitCycleRecord({
    String? id,
    required DateTime periodStartDate,
    DateTime? periodEndDate,
    String? note,
  }) async {
    final controller = AppScope.read(context);
    if (!controller.canUseCycleRecords) return false;
    if (_hasOverlappingCycleRecord(
      ownerProfileId: controller.selfProfileId,
      recordId: id,
      startDate: periodStartDate,
      endDate: periodEndDate,
    )) {
      return false;
    }

    setState(() => _submitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;
      final coupleSpaceId = controller.currentSpaceId;
      if (coupleSpaceId == null) return false;

      final payload = {
        'period_start_date': _formatDateForStorage(periodStartDate),
        'period_end_date': periodEndDate == null
            ? null
            : _formatDateForStorage(periodEndDate),
        'note': note?.trim().isEmpty == true ? null : note?.trim(),
      };

      if (id == null) {
        await Supabase.instance.client.from('cycle_records').insert({
          ...payload,
          'couple_space_id': coupleSpaceId,
          'owner_profile_id': user.id,
          'shared_with_partner': controller.cycleSharingEnabled,
        });
      } else {
        await Supabase.instance.client
            .from('cycle_records')
            .update(payload)
            .eq('id', id)
            .eq('couple_space_id', coupleSpaceId)
            .eq('owner_profile_id', user.id);
      }

      await _loadEvents(force: true);
      return true;
    } catch (e) {
      debugPrint('[Calendar] submitCycleRecord failed: $e');
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
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final event = _eventById(eventId);
      final targetSpaceId = event?.coupleSpaceId ?? coupleSpaceId;
      final deletedRows = await Supabase.instance.client
          .from('calendar_events')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', eventId)
          .eq('couple_space_id', targetSpaceId)
          .eq('created_by', userId)
          .isFilter('deleted_at', null)
          .select('id');
      if ((deletedRows as List).isEmpty) {
        throw StateError(
          'calendar_events soft delete matched 0 rows: '
          'eventId=$eventId, coupleSpaceId=$targetSpaceId, userId=$userId',
        );
      }

      if (mounted) {
        _removeEventLocally(eventId);
      }
      await _loadEvents(force: true);
    } catch (e) {
      debugPrint('[Calendar] deleteEvent failed: $e');
      if (mounted) {
        final strings = AppStrings.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.calendarDeleteFailedError)),
        );
      }
    }
  }

  Future<void> _deleteCycleRecord(String recordId) async {
    final controller = AppScope.read(context);
    if (!controller.canUseCycleRecords) return;
    final coupleSpaceId = controller.currentSpaceId;
    if (coupleSpaceId == null) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final deletedRows = await Supabase.instance.client
          .from('cycle_records')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', recordId)
          .eq('couple_space_id', coupleSpaceId)
          .eq('owner_profile_id', userId)
          .isFilter('deleted_at', null)
          .select('id');
      if ((deletedRows as List).isEmpty) {
        throw StateError(
          'cycle_records soft delete matched 0 rows: '
          'recordId=$recordId, coupleSpaceId=$coupleSpaceId, userId=$userId',
        );
      }

      if (mounted) {
        setState(() {
          _cycleRecords = _cycleRecords
              .where((record) => record.id != recordId)
              .toList();
        });
      }
      await _loadEvents(force: true);
    } catch (e) {
      debugPrint('[Calendar] deleteCycleRecord failed: $e');
      if (mounted) {
        final strings = AppStrings.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.cycleDeleteFailedError)));
      }
    }
  }

  CalendarEventRecord? _eventById(String eventId) {
    for (final event in _events) {
      if (event.id == eventId) return event;
    }
    return null;
  }

  void _upsertEventLocally(CalendarEventRecord record) {
    setState(() {
      _events = [..._events.where((event) => event.id != record.id), record]
        ..sort((left, right) => left.startsAt.compareTo(right.startsAt));
      _eventCreators = {for (final event in _events) event.id: event.createdBy};
    });
  }

  void _removeEventLocally(String eventId) {
    setState(() {
      _events = _events.where((event) => event.id != eventId).toList();
      _eventCreators.remove(eventId);
    });
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

  void _confirmDeleteCycleRecord(CycleRecord record) {
    final strings = AppStrings.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.cycleDeleteConfirmTitle),
        content: Text(strings.cycleDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.profileCancelLabel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteCycleRecord(record.id);
            },
            child: Text(strings.calendarDeleteButton),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    final strings = AppStrings.of(context);
    final canUseCycleRecords = AppScope.read(context).canUseCycleRecords;
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
                    if (canUseCycleRecords)
                      ChoiceChip(
                        label: Text(
                          strings.calendarTypeLabel(CalendarEntryType.cycle),
                        ),
                        selected: selectedType == 'cycle',
                        onSelected: (selected) {
                          if (selected) {
                            Navigator.pop(context);
                            _showCycleDialog();
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

  void _showCycleDialog({CycleRecord? record}) {
    final strings = AppStrings.of(context);
    final noteController = TextEditingController(text: record?.note ?? '');
    DateTime startDate =
        record?.periodStartDate ?? _selectedDate ?? DateTime.now();
    DateTime? endDate = record?.periodEndDate;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            record == null
                ? strings.cycleCreateDialogTitle
                : strings.cycleEditDialogTitle,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(strings.cycleStartDateLabel),
                  subtitle: Text(_formatDateLabel(context, startDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        startDate = _dateOnly(picked);
                        if (endDate != null && endDate!.isBefore(startDate)) {
                          endDate = startDate;
                        }
                      });
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_available_outlined),
                  title: Text(strings.cycleEndDateLabel),
                  subtitle: Text(
                    endDate == null
                        ? strings.cycleEndDateUnsetLabel
                        : _formatDateLabel(context, endDate!),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? startDate,
                      firstDate: startDate,
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() => endDate = _dateOnly(picked));
                    }
                  },
                  trailing: endDate == null
                      ? null
                      : IconButton(
                          onPressed: () {
                            setDialogState(() => endDate = null);
                          },
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: strings.cycleEndDateUnsetLabel,
                        ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(hintText: strings.cycleNoteHint),
                  maxLines: 3,
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
                      final success = await _submitCycleRecord(
                        id: record?.id,
                        periodStartDate: startDate,
                        periodEndDate: endDate,
                        note: noteController.text,
                      );

                      if (success && context.mounted) {
                        Navigator.pop(context);
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(strings.cycleCreateFailedError),
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
                  : Text(strings.cycleSaveButton),
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
    final visibleCycleRecords = _visibleCycleRecords(AppScope.of(context));

    final filteredEntries = _filterEntries(entries);
    final filteredCycleRecords = _filterCycleRecords(visibleCycleRecords);

    final entriesByDay = _groupEntriesByDay(
      entries: filteredEntries,
      visibleDays: visibleDays,
    );
    final cycleRecordsByDay = _groupCycleRecordsByDay(
      records: filteredCycleRecords,
      visibleDays: visibleDays,
    );
    final selectedEntries =
        filteredEntries
            .where((entry) => entry.occursOn(_selectedDate!))
            .toList()
          ..sort(
            (left, right) => _occurrenceOnDay(
              left,
              _selectedDate!,
            ).compareTo(_occurrenceOnDay(right, _selectedDate!)),
          );
    final selectedCycleRecords =
        filteredCycleRecords
            .where((record) => _cycleOccursOn(record, _selectedDate!))
            .toList()
          ..sort(
            (left, right) =>
                left.periodStartDate.compareTo(right.periodStartDate),
          );
    final upcomingEntries = _getUpcomingEntries(filteredEntries, now);

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppTheme.pageBackgroundDark
                  : AppTheme.pageBackgroundLight,
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppTheme.pageAtmosphereDark
                    : AppTheme.pageAtmosphereLight,
              ),
            ),
          ),
        ),
        NotificationListener<ScrollNotification>(
          onNotification: _handleCalendarScroll,
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // ── Month grid ──
                PageSurfaceCard(
                  padding: const EdgeInsets.all(14),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _MonthView(
                      displayMonth: _displayMonth,
                      visibleDays: visibleDays,
                      selectedDate: _selectedDate!,
                      entriesByDay: entriesByDay,
                      cycleRecordsByDay: cycleRecordsByDay,
                      expanded: _calendarExpanded,
                      onToggleExpanded: () =>
                          _setCalendarExpanded(!_calendarExpanded),
                      onSelectDate: _selectCalendarDay,
                      onAddEvent: _showCreateDialog,
                      onPreviousMonth: _previousMonth,
                      onNextMonth: _nextMonth,
                      isDark: isDark,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Event type filter chips ──
                _FilterChipRow(
                  activeFilter: _activeFilter,
                  canUseCycleRecords: AppScope.of(context).canUseCycleRecords,
                  onSelected: (filter) {
                    setState(() => _activeFilter = filter);
                  },
                ),
                const SizedBox(height: 16),

                // ── Selected date details ──
                PageSectionHeader(title: strings.calendarDetailsTitle),
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
                      if (selectedEntries.isEmpty &&
                          selectedCycleRecords.isEmpty)
                        _SelectedDayEmptyState(strings: strings, isDark: isDark)
                      else ...[
                        ...selectedCycleRecords.map((record) {
                          final isOwner =
                              record.ownerProfileId ==
                              AppScope.of(context).selfProfileId;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SelectedCycleRecordCard(
                              record: record,
                              isDark: isDark,
                              isOwner: isOwner,
                              onEdit: isOwner
                                  ? () => _showCycleDialog(record: record)
                                  : null,
                              onDelete: isOwner
                                  ? () => _confirmDeleteCycleRecord(record)
                                  : null,
                            ),
                          );
                        }),
                        ...selectedEntries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SelectedEntryCard(
                              entry: entry,
                              occurrence: _occurrenceOnDay(
                                entry,
                                _selectedDate!,
                              ),
                              isDark: isDark,
                              onDelete:
                                  _eventCreators[entry.id] ==
                                      AppScope.of(context).selfProfileId
                                  ? () => _confirmDeleteEvent(
                                      entry.id,
                                      entry.title,
                                    )
                                  : null,
                              createdBy: _eventCreators[entry.id],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Upcoming events ──
                PageSectionHeader(title: strings.calendarUpcomingTitle),
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
                        onDelete:
                            _eventCreators[item.entry.id] ==
                                AppScope.of(context).selfProfileId
                            ? () => _confirmDeleteEvent(
                                item.entry.id,
                                item.entry.title,
                              )
                            : null,
                        createdBy: _eventCreators[item.entry.id],
                      ),
                    ),
                  ),
              ],
            ),
          ),
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

  Map<String, List<CycleRecord>> _groupCycleRecordsByDay({
    required List<CycleRecord> records,
    required List<DateTime> visibleDays,
  }) {
    final grouped = <String, List<CycleRecord>>{};

    for (final day in visibleDays) {
      final items = records.where((record) => _cycleOccursOn(record, day));
      for (final item in items) {
        (grouped[_dateKey(day)] ??= []).add(item);
      }
    }

    return grouped;
  }

  bool _hasOverlappingCycleRecord({
    required String? ownerProfileId,
    required String? recordId,
    required DateTime startDate,
    required DateTime? endDate,
  }) {
    if (ownerProfileId == null) {
      return true;
    }
    final newStart = _dateOnly(startDate);
    final newEnd = _dateOnly(endDate ?? startDate);
    return _cycleRecords.any((record) {
      if (record.deletedAt != null ||
          record.ownerProfileId != ownerProfileId ||
          record.id == recordId) {
        return false;
      }
      final existingStart = _dateOnly(record.periodStartDate);
      final existingEnd = _dateOnly(
        record.periodEndDate ?? record.periodStartDate,
      );
      return !newStart.isAfter(existingEnd) && !newEnd.isBefore(existingStart);
    });
  }

  List<CycleRecord> _visibleCycleRecords(AppController controller) {
    final selfId = controller.selfProfileId;
    if (selfId == null) {
      return const [];
    }
    return _cycleRecords
        .where(
          (record) =>
              record.deletedAt == null &&
              (record.ownerProfileId == selfId || record.sharedWithPartner),
        )
        .where(
          (record) =>
              record.ownerProfileId == selfId ||
              record.ownerCycleSharingEnabled,
        )
        .toList();
  }

  List<CalendarEntryData> _filterEntries(List<CalendarEntryData> entries) {
    if (_activeFilter == CalendarFilter.all) return entries;
    final targetType = switch (_activeFilter) {
      CalendarFilter.anniversary => CalendarEntryType.anniversary,
      CalendarFilter.datePlan => CalendarEntryType.datePlan,
      CalendarFilter.reminder => CalendarEntryType.reminder,
      CalendarFilter.cycle => null,
      CalendarFilter.all => null,
    };
    if (targetType == null) return const [];
    return entries.where((e) => e.type == targetType).toList();
  }

  List<CycleRecord> _filterCycleRecords(List<CycleRecord> records) {
    if (_activeFilter == CalendarFilter.all ||
        _activeFilter == CalendarFilter.cycle) {
      return records;
    }
    return const [];
  }

  static bool _cycleOccursOn(CycleRecord record, DateTime day) {
    final date = _dateOnly(day);
    final start = _dateOnly(record.periodStartDate);
    final end = _dateOnly(record.periodEndDate ?? record.periodStartDate);
    return !date.isBefore(start) && !date.isAfter(end);
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

  static String _formatDateForStorage(DateTime value) {
    final normalized = _dateOnly(value);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  String _formatDateLabel(BuildContext context, DateTime date) {
    return AppStrings.of(context).formatCalendarDate(_dateOnly(date));
  }
}

// ─── Month View ─────────────────────────────────────────────────────────

bool _sameCalendarDate(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

class _MonthView extends StatelessWidget {
  const _MonthView({
    required this.displayMonth,
    required this.visibleDays,
    required this.selectedDate,
    required this.entriesByDay,
    required this.cycleRecordsByDay,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onSelectDate,
    required this.isDark,
    this.onAddEvent,
    this.onPreviousMonth,
    this.onNextMonth,
  });

  final DateTime displayMonth;
  final List<DateTime> visibleDays;
  final DateTime selectedDate;
  final Map<String, List<CalendarEntryData>> entriesByDay;
  final Map<String, List<CycleRecord>> cycleRecordsByDay;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<DateTime> onSelectDate;
  final bool isDark;
  final VoidCallback? onAddEvent;
  final VoidCallback? onPreviousMonth;
  final VoidCallback? onNextMonth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = AppStrings.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final dayCellHeight = 46.0 + ((textScale - 1) * 48).clamp(0, 34).toDouble();

    return Column(
      children: [
        Row(
          children: [
            if (onPreviousMonth != null)
              IconButton(
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left, size: 20),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            Expanded(
              child: Text(
                strings.formatCalendarMonthYear(displayMonth),
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onNextMonth != null)
              IconButton(
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right, size: 20),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            if (onAddEvent != null)
              IconButton(
                onPressed: onAddEvent,
                icon: const Icon(Icons.add, size: 20),
                tooltip: strings.createCalendarEntrySection,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            IconButton(
              key: const ValueKey('calendar-toggle-month-view'),
              onPressed: onToggleExpanded,
              icon: Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 20,
              ),
              tooltip: expanded
                  ? strings.calendarCollapseMonthLabel
                  : strings.calendarExpandMonthLabel,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
        Semantics(
          container: true,
          child: KeyedSubtree(
            key: ValueKey(
              expanded ? 'calendar-month-view' : 'calendar-week-view',
            ),
            child: Column(
              children: [
                for (var index = 0; index < visibleDays.length; index += 7)
                  _CalendarWeekRow(
                    key: ValueKey('calendar-week-row-${index ~/ 7}'),
                    weekDays: visibleDays.sublist(index, index + 7),
                    displayMonth: displayMonth,
                    selectedDate: selectedDate,
                    entriesByDay: entriesByDay,
                    cycleRecordsByDay: cycleRecordsByDay,
                    expanded: expanded,
                    isDark: isDark,
                    cellHeight: dayCellHeight,
                    onSelectDate: onSelectDate,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Day Cell ───────────────────────────────────────────────────────────

class _CalendarWeekRow extends StatelessWidget {
  const _CalendarWeekRow({
    super.key,
    required this.weekDays,
    required this.displayMonth,
    required this.selectedDate,
    required this.entriesByDay,
    required this.cycleRecordsByDay,
    required this.expanded,
    required this.isDark,
    required this.cellHeight,
    required this.onSelectDate,
  });

  final List<DateTime> weekDays;
  final DateTime displayMonth;
  final DateTime selectedDate;
  final Map<String, List<CalendarEntryData>> entriesByDay;
  final Map<String, List<CycleRecord>> cycleRecordsByDay;
  final bool expanded;
  final bool isDark;
  final double cellHeight;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final isSelectedWeek = weekDays.any(
      (day) => _sameCalendarDate(day, selectedDate),
    );
    final rowVisible = expanded || isSelectedWeek;
    final row = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          _CycleBandRow(
            weekDays: weekDays,
            cycleRecordsByDay: cycleRecordsByDay,
            displayMonth: displayMonth,
            selectedDate: selectedDate,
            isDark: isDark,
            cellHeight: cellHeight,
          ),
          Row(
            children: [
              for (final day in weekDays)
                Expanded(
                  child: _DayCell(
                    date: day,
                    inMonth: day.month == displayMonth.month,
                    selected: _sameCalendarDate(day, selectedDate),
                    hasEntries: entriesByDay.containsKey(_dateKey(day)),
                    onTap: () => onSelectDate(day),
                    isDark: isDark,
                    height: cellHeight,
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    return IgnorePointer(
      ignoring: !rowVisible,
      child: ClipRect(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: rowVisible ? 1 : 0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          builder: (context, factor, child) {
            return Align(
              alignment: Alignment.topCenter,
              heightFactor: factor,
              child: Opacity(opacity: factor.clamp(0, 1), child: child),
            );
          },
          child: row,
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.inMonth,
    required this.selected,
    required this.hasEntries,
    required this.onTap,
    required this.isDark,
    required this.height,
  });

  final DateTime date;
  final bool inMonth;
  final bool selected;
  final bool hasEntries;
  final VoidCallback onTap;
  final bool isDark;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final background = selected
        ? colorScheme.primary
        : hasEntries
        ? (isDark
              ? Colors.white.withValues(alpha: 0.06)
              : colorScheme.primary.withValues(alpha: 0.1))
        : Colors.transparent;
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
          child: SizedBox(
            height: height,
            child: DecoratedBox(
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
                  _DayMarkerDot(
                    visible: hasEntries,
                    color: selected
                        ? colorScheme.onPrimary
                        : (isDark
                              ? AppTheme.heroGlowBlush
                              : colorScheme.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayMarkerDot extends StatelessWidget {
  const _DayMarkerDot({required this.visible, required this.color});

  final bool visible;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: visible ? color : Colors.transparent,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─── Cycle Band Row ──────────────────────────────────────────────────────

class _CycleBandRow extends StatelessWidget {
  const _CycleBandRow({
    required this.weekDays,
    required this.cycleRecordsByDay,
    required this.displayMonth,
    required this.selectedDate,
    required this.isDark,
    required this.cellHeight,
  });

  final List<DateTime> weekDays;
  final Map<String, List<CycleRecord>> cycleRecordsByDay;
  final DateTime displayMonth;
  final DateTime selectedDate;
  final bool isDark;
  final double cellHeight;

  @override
  Widget build(BuildContext context) {
    // Determine which days in this week row are cycle days (in current month).
    final cycleDays = <int>{};
    for (var i = 0; i < weekDays.length; i++) {
      final day = weekDays[i];
      if (day.month != displayMonth.month) continue;
      if (cycleRecordsByDay.containsKey(_dateKey(day))) {
        cycleDays.add(i);
      }
    }

    if (cycleDays.isEmpty) return const SizedBox.shrink();

    // Build segments: groups of consecutive cycle days.
    final segments = _buildSegments(cycleDays);

    final bandColor = _cycleMarkerColor(
      isDark,
    ).withValues(alpha: isDark ? 0.22 : 0.12);

    return Row(
      children: List.generate(7, (i) {
        final segment = _segmentForIndex(segments, i);
        if (segment == null) {
          return const Expanded(child: SizedBox.shrink());
        }

        final isStart = i == segment.start;
        final isEnd = i == segment.end;
        final isSingle = segment.isSingle;
        final isSelected = _sameDate(weekDays[i], selectedDate);

        // Don't show band when the day is selected.
        if (isSelected) {
          return const Expanded(child: SizedBox.shrink());
        }

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              height: cellHeight,
              decoration: BoxDecoration(
                color: bandColor,
                borderRadius: BorderRadius.horizontal(
                  left: isStart || isSingle
                      ? const Radius.circular(AppTheme.radiusMd)
                      : const Radius.circular(2),
                  right: isEnd || isSingle
                      ? const Radius.circular(AppTheme.radiusMd)
                      : const Radius.circular(2),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Build consecutive segments from a set of day indices.
  static List<_CycleSegment> _buildSegments(Set<int> days) {
    if (days.isEmpty) return const [];
    final sorted = days.toList()..sort();
    final segments = <_CycleSegment>[];
    var start = sorted[0];
    var end = sorted[0];

    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i] == end + 1) {
        end = sorted[i];
      } else {
        segments.add(_CycleSegment(start, end));
        start = sorted[i];
        end = sorted[i];
      }
    }
    segments.add(_CycleSegment(start, end));
    return segments;
  }

  /// Find which segment (if any) contains the given index.
  static _CycleSegment? _segmentForIndex(List<_CycleSegment> segments, int i) {
    for (final seg in segments) {
      if (i >= seg.start && i <= seg.end) return seg;
    }
    return null;
  }

  static bool _sameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

class _CycleSegment {
  const _CycleSegment(this.start, this.end);

  final int start;
  final int end;

  bool get isSingle => start == end;
}

// ─── Filter Chip Row ─────────────────────────────────────────────────────

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.activeFilter,
    required this.canUseCycleRecords,
    required this.onSelected,
  });

  final CalendarFilter activeFilter;
  final bool canUseCycleRecords;
  final ValueChanged<CalendarFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final filters = [
      CalendarFilter.all,
      CalendarFilter.anniversary,
      CalendarFilter.datePlan,
      CalendarFilter.reminder,
      if (canUseCycleRecords) CalendarFilter.cycle,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final filter in filters)
          _buildChip(context, strings, colorScheme, isDark, filter),
      ],
    );
  }

  Widget _buildChip(
    BuildContext context,
    AppStrings strings,
    ColorScheme colorScheme,
    bool isDark,
    CalendarFilter filter,
  ) {
    final isSelected = activeFilter == filter;
    final label = strings.calendarFilterLabel(filter);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(filter),
      selectedColor: isDark
          ? AppTheme.darkBlush.withValues(alpha: 0.5)
          : AppTheme.blushLight,
      backgroundColor: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : AppTheme.warmGray50,
      side: BorderSide(
        color: isSelected
            ? (isDark
                  ? AppTheme.darkBlushAccent.withValues(alpha: 0.6)
                  : colorScheme.primary.withValues(alpha: 0.4))
            : (isDark ? AppTheme.nightBorder : AppTheme.warmGray200),
      ),
      labelStyle: TextStyle(
        color: isSelected
            ? (isDark ? AppTheme.warmWhite90 : colorScheme.primary)
            : (isDark ? AppTheme.warmWhite60 : colorScheme.onSurfaceVariant),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 13,
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
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
    this.createdBy,
  });

  final CalendarEntryData entry;
  final DateTime occurrence;
  final bool isDark;
  final VoidCallback? onDelete;
  final String? createdBy;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageIconBadge(
                  icon: _iconForType(entry.type),
                  color: _colorForType(entry.type),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        _MetaChip(label: strings.calendarTypeLabel(entry.type)),
                        _MetaChip(
                          label: strings.calendarRepeatLabel(entry.repeatRule),
                        ),
                      ],
                    ),
                  ),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
            if (entry.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                entry.description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
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
            if (createdBy != null &&
                AppScope.of(context).hasActiveCoupleSpace) ...[
              const SizedBox(height: 8),
              _buildAuthorLabel(context, createdBy!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorLabel(BuildContext context, String creatorId) {
    final controller = AppScope.of(context);
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final name = creatorId == controller.selfProfileId
        ? (controller.displayName ?? (strings.isChinese ? '我' : 'Me'))
        : (controller.partnerDisplayName ??
              (strings.isChinese ? 'TA' : 'Partner'));

    return Text(
      strings.createdByLabel(name),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: isDark ? AppTheme.warmWhite60 : colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _SelectedCycleRecordCard extends StatelessWidget {
  const _SelectedCycleRecordCard({
    required this.record,
    required this.isDark,
    required this.isOwner,
    this.onEdit,
    this.onDelete,
  });

  final CycleRecord record;
  final bool isDark;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final start = strings.formatCalendarDate(record.periodStartDate);
    final end = record.periodEndDate == null
        ? null
        : strings.formatCalendarDate(record.periodEndDate!);
    final range = end == null
        ? start
        : '$start ${strings.cycleDateRangeSeparator} $end';

    return PageSurfaceCard(
      variant: PageSurfaceVariant.secondary,
      padding: EdgeInsets.zero,
      child: Padding(
        key: ValueKey('cycle-detail-${record.id}'),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageIconBadge(
                  icon: Icons.water_drop_outlined,
                  color: _cycleMarkerColor(isDark),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        if (!isOwner)
                          _MetaChip(label: strings.cyclePartnerRecordLabel),
                      ],
                    ),
                  ),
                ),
                if (onEdit != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: strings.profileEditLabel,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
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
              strings.calendarTypeLabel(CalendarEntryType.cycle),
              key: ValueKey('cycle-detail-title-${record.id}'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              range,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            if (record.note != null && record.note!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                record.note!,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppTheme.warmWhite60
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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
    this.createdBy,
  });

  final CalendarEntryData entry;
  final DateTime occurrence;
  final bool isDark;
  final VoidCallback? onDelete;
  final String? createdBy;

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
                  Text(
                    entry.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (entry.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      entry.description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
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
                  if (createdBy != null &&
                      AppScope.of(context).hasActiveCoupleSpace) ...[
                    const SizedBox(height: 6),
                    _buildAuthorLabel(context, createdBy!),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    strings.formatCountdownLabel(occurrence, DateTime.now()),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorLabel(BuildContext context, String creatorId) {
    final controller = AppScope.of(context);
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final name = creatorId == controller.selfProfileId
        ? (controller.displayName ?? (strings.isChinese ? '我' : 'Me'))
        : (controller.partnerDisplayName ??
              (strings.isChinese ? 'TA' : 'Partner'));

    return Text(
      strings.createdByLabel(name),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: isDark ? AppTheme.warmWhite60 : colorScheme.onSurfaceVariant,
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
            Text(
              strings.calendarNoEventsYet,
              style: theme.textTheme.titleMedium,
            ),
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
            Text(
              strings.calendarNoEventsYet,
              style: theme.textTheme.titleMedium,
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

// ─── Helpers ────────────────────────────────────────────────────────────

IconData _iconForType(CalendarEntryType type) {
  return switch (type) {
    CalendarEntryType.anniversary => Icons.favorite_rounded,
    CalendarEntryType.datePlan => Icons.event_available_outlined,
    CalendarEntryType.reminder => Icons.notifications_outlined,
    CalendarEntryType.cycle => Icons.water_drop_outlined,
  };
}

Color _colorForType(CalendarEntryType type) {
  return switch (type) {
    CalendarEntryType.anniversary => AppTheme.blush,
    CalendarEntryType.datePlan => AppTheme.gold,
    CalendarEntryType.reminder => AppTheme.sage,
    CalendarEntryType.cycle => AppTheme.berry,
  };
}

Color _cycleMarkerColor(bool isDark) =>
    isDark ? AppTheme.darkFog : AppTheme.berry;

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
