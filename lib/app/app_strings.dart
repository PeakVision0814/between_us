import 'package:flutter/material.dart';

import 'app_controller.dart';

class AppStrings {
  const AppStrings._(this.language);

  final AppLanguage language;

  bool get isChinese => language == AppLanguage.zhCn;

  static AppStrings of(BuildContext context) {
    final controller = AppScope.of(context);
    return AppStrings._(controller.language);
  }

  String get appName => 'Between Us';

  String get homeTab => isChinese ? '首页' : 'Home';
  String get calendarTab => isChinese ? '日历' : 'Calendar';
  String get plansNotesTab => isChinese ? '计划笔记' : 'Plans & Notes';
  String get usTab => isChinese ? '我们' : 'Us';

  String get homeTitle =>
      isChinese ? '今天先看看这些' : 'A few things worth checking today';
  String get homeSubtitle => isChinese
      ? '重要日子、最近动态和手边计划，都先放回同一个地方。'
      : 'Keep your next date, latest update, and nearby plans in one shared place.';

  String get overviewSection => isChinese ? '我们概览' : 'Our overview';
  String get nextDateSection => isChinese ? '下一个重要日期' : 'Next important date';
  String get recentUpdateSection =>
      isChinese ? '最近动态预览' : 'Latest shared update';
  String get recentPlanSection =>
      isChinese ? '最近一个计划提醒' : 'One plan worth moving';
  String get quickLinksSection => isChinese ? '快捷入口' : 'Quick actions';

  String get writeNoteLabel => isChinese ? '写随记' : 'Write a note';
  String get createPlanLabel => isChinese ? '新建计划' : 'New plan';
  String get goCalendarLabel => isChinese ? '去日历' : 'Open calendar';
  String get goUsLabel => isChinese ? '去我们' : 'Open Us';

  String get avatarLabelOne => isChinese ? '满' : 'X';
  String get avatarLabelTwo => isChinese ? '澈' : 'A';
  String get coupleNames => isChinese ? '小满 和 阿澈' : 'Xiaoman & Ache';
  String get relationshipStatus => isChinese ? '一起第 214 天' : 'Day 214 together';
  String get relationshipMood => isChinese
      ? '这周都不算太忙，周五晚上留给一起出门。'
      : 'This week feels calm enough. Friday night is still saved for the two of you.';
  String get spaceStatusLabel => isChinese ? '空间状态' : 'Space status';
  String get spaceStatusValue => isChinese ? '稳定同步中' : 'Steady and shared';
  String get overviewChipOne => isChinese ? '今晚都在线' : 'Both around tonight';
  String get overviewChipTwo => isChinese ? '周五留给约会' : 'Friday kept for a date';

  String get noteComposerTitle =>
      isChinese ? '想留一句话时，就写在这里' : 'Leave a note whenever it feels right';
  String get noteComposerHint =>
      isChinese ? '不用写很多，想到什么就留一点。' : 'Keep it light. A few words are enough.';
  String get noteComposerExample => isChinese
      ? '比如：回来的路上别忘了买点水果，我想留一半给明天早上。'
      : 'For example: grab some fruit on the way back. I want to save half for tomorrow morning.';

  List<String> get weekLabels => isChinese
      ? const ['一', '二', '三', '四', '五', '六', '日']
      : const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  String get monthYearLabel => isChinese ? '2026 年 6 月' : 'June 2026';

  String get calendarTitle => calendarTab;
  String get calendarLeadTitle => isChinese ? '本月安排' : 'This month at a glance';
  String get calendarLeadSubtitle => isChinese
      ? '纪念日、约会和提醒，都放在这里。'
      : 'Anniversaries, scheduled plans, and reminders stay here.';
  String get selectedDateSection =>
      isChinese ? '选中日期详情' : 'Selected date details';
  String get upcomingEventsSection => isChinese ? '近期事项' : 'Coming up soon';
  String get createCalendarEntrySection =>
      isChinese ? '新建日历项' : 'Add to calendar';
  String get selectedDateLabel =>
      isChinese ? '6 月 6 日 · 周六' : 'June 6 · Saturday';
  String get createAnniversaryLabel => isChinese ? '纪念日' : 'Anniversary';
  String get createDatePlanLabel => isChinese ? '约会' : 'Date plan';
  String get createReminderLabel => isChinese ? '提醒' : 'Reminder';
  String get periodPlaceholderLabel => isChinese
      ? '经期记录以后会放在日历里，但会单独区分，也不会默认共享。'
      : 'Cycle records will appear in calendar later, clearly separated and never shared by default.';

  String get plansNotesTitle => plansNotesTab;
  String get plansNotesLeadTitle =>
      isChinese ? '没定日期的，先放这里' : 'Keep undecided things here first';
  String get plansNotesLeadSubtitle => isChinese
      ? '有日期的去日历，没日期的计划和随记留在这里。'
      : 'Dated items belong in calendar. Undated plans and notes stay here.';
  String get plansSectionTitle => isChinese ? '计划' : 'Plans';
  String get plansSectionSubtitle => isChinese
      ? '还没定日期的想法、待讨论事项和约会意向。'
      : 'Undated ideas, date intentions, and things to discuss.';
  String get notesSectionTitle => isChinese ? '随记' : 'Notes';
  String get notesSectionSubtitle => isChinese
      ? '随手记下的小事、心情和共享日常。'
      : 'Light shared notes, little thoughts, and daily moments.';
  String get moveToCalendarLabel =>
      isChinese ? '以后放进日历' : 'Later move to calendar';
  String get addPlanLabel => isChinese ? '加一个计划' : 'Add a plan';
  String get addNoteLabel => isChinese ? '写一条随记' : 'Write a note';

  String get planModeLeadTitle =>
      isChinese ? '想做的事，先记在这里' : 'Jot down what you want to do';
  String get planModeLeadSubtitle => isChinese
      ? '不用马上定日期，想到了就先放着，等准备好了再挪去日历。'
      : 'No need to set a date right away. Park it here and move it to calendar when ready.';
  String get noteModeLeadTitle =>
      isChinese ? '随手留一点，给彼此看看' : 'Leave a little something for each other';
  String get noteModeLeadSubtitle => isChinese
      ? '不用写很多，一句话、一个念头、一点日常碎片都好。'
      : 'A sentence, a thought, a small daily moment — anything counts.';
  String get switchToNotesHint =>
      isChinese ? '看看随记' : 'Switch to notes';
  String get switchToPlansHint =>
      isChinese ? '看看计划' : 'Switch to plans';

  String get usTitle => usTab;
  String get usLeadTitle => isChinese ? '我们的空间' : 'Our shared space';
  String get usLeadSubtitle => isChinese
      ? '把自己的偏好和两个人一起用的规则，都放在同一个地方。'
      : 'Keep your personal preferences and shared space rules together.';
  String get preferencesSection => isChinese ? '我的偏好' : 'My preferences';
  String get spaceSection => isChinese ? '我们的空间' : 'Our space';
  String get privacySection => isChinese ? '隐私与共享' : 'Privacy & sharing';
  String get languageTitle => isChinese ? '语言' : 'Language';
  String get themeTitle => isChinese ? '主题模式' : 'Theme mode';
  String get timeZoneTitle => isChinese ? '时区' : 'Time zone';
  String get timeZoneHint => isChinese
      ? '首页、日历和随记时间都会按这里展示。'
      : 'Home, calendar, and note times follow this device time zone.';
  String get notificationPreviewTitle =>
      isChinese ? '通知预览' : 'Notification previews';
  String get notificationPreviewSubtitle => isChinese
      ? '在通知里直接显示随记和提醒内容。'
      : 'Show note and reminder text directly inside notifications.';
  String get spaceNameTitle => isChinese ? '空间名称' : 'Space name';
  String get inviteStatusTitle => isChinese ? '邀请状态' : 'Invite status';
  String get sharedRulesTitle => isChinese ? '共享规则' : 'Shared rules';
  String get relationshipDateTitle => isChinese ? '关系起点' : 'Relationship date';
  String get cyclePrivacyTitle => isChinese ? '经期记录共享规则' : 'Cycle sharing rule';
  String get exportUnlinkTitle => isChinese ? '导出与解绑' : 'Export and unlink';
  String get localPrototypeHint => isChinese
      ? '这些设置现在只在本地原型里生效，真实同步会在共享阶段接入。'
      : 'These settings only live in the local prototype for now. Real sync comes in the shared stage.';

  String get chineseLabel => '简体中文';
  String get englishLabel => 'English';
  String get themeSystemLabel => isChinese ? '跟随系统' : 'System';
  String get themeLightLabel => isChinese ? '浅色' : 'Light';
  String get themeDarkLabel => isChinese ? '深色' : 'Dark';

  List<CalendarItemCopy> get calendarItems => [
        for (final item in calendarUpcomingEntries)
          calendarItemCopyForOccurrence(item),
      ];

/*
      ? const [
          CalendarItemCopy(
            title: '关系纪念日',
            subtitle: '晚饭想去河边那家小店',
            dateLabel: '6 月 6 日',
            countdownLabel: '还有 12 天',
            typeLabel: '纪念日',
          ),
          CalendarItemCopy(
            title: '周五约会夜',
            subtitle: '电影还没定，先把时间留出来',
            dateLabel: '5 月 29 日 19:30',
            countdownLabel: '3 天后',
            typeLabel: '约会',
          ),
          CalendarItemCopy(
            title: '给阳台植物浇水',
            subtitle: '顺手把新的花盆也挑一下',
            dateLabel: '5 月 27 日 20:00',
            countdownLabel: '明天',
            typeLabel: '提醒',
          ),
        ]
      : const [
          CalendarItemCopy(
            title: 'Relationship anniversary',
            subtitle: 'Dinner could be at the little riverside place',
            dateLabel: 'June 6',
            countdownLabel: '12 days left',
            typeLabel: 'Anniversary',
          ),
          CalendarItemCopy(
            title: 'Friday date night',
            subtitle: 'Movie not chosen yet, but the time is already saved',
            dateLabel: 'May 29, 7:30 PM',
            countdownLabel: 'In 3 days',
            typeLabel: 'Date',
          ),
          CalendarItemCopy(
            title: 'Water the balcony plants',
            subtitle: 'Also pick a new pot while you are at it',
            dateLabel: 'May 27, 8:00 PM',
            countdownLabel: 'Tomorrow',
            typeLabel: 'Reminder',
          ),
        ];

*/
  List<PlanItemCopy> get plans => isChinese
      ? const [
          PlanItemCopy(
            title: '把六月短途出门定下来',
            body: '先决定是去海边还是去山里，别拖到最后一周。',
            statusLabel: '待讨论',
            helperLabel: '还没定日期',
          ),
          PlanItemCopy(
            title: '给客厅换一盏更暖的落地灯',
            body: '想找一盏晚上看书时更舒服的灯。',
            statusLabel: '想法中',
            helperLabel: '生活计划',
          ),
          PlanItemCopy(
            title: '把七月那顿生日饭店先挑出来',
            body: '定下来以后就可以放进日历。',
            statusLabel: '准备安排',
            helperLabel: '可转入日历',
          ),
        ]
      : const [
          PlanItemCopy(
            title: 'Settle the short June getaway',
            body:
                'Pick sea or mountains before the last week sneaks up on you.',
            statusLabel: 'To discuss',
            helperLabel: 'No date yet',
          ),
          PlanItemCopy(
            title: 'Find a warmer floor lamp for the living room',
            body: 'Something that feels better when reading at night.',
            statusLabel: 'Idea',
            helperLabel: 'Home plan',
          ),
          PlanItemCopy(
            title: 'Pick the July birthday dinner place early',
            body: 'Once it is decided, it can move into calendar.',
            statusLabel: 'Ready to schedule',
            helperLabel: 'Can move to calendar',
          ),
        ];

  List<NoteItemCopy> get notes => isChinese
      ? const [
          NoteItemCopy(author: '阿澈', timeLabel: '刚刚', text: '到家啦，楼下买到了你喜欢的豆花。'),
          NoteItemCopy(
            author: '小满',
            timeLabel: '昨晚 21:18',
            text: '今天风有点大，回来的时候记得把外套拉好。',
          ),
          NoteItemCopy(
            author: '阿澈',
            timeLabel: '周日 17:40',
            text: '下次还想跟你去那家小店，汤底真的很暖。',
          ),
        ]
      : const [
          NoteItemCopy(
            author: 'Ache',
            timeLabel: 'Just now',
            text:
                'I am home. The tofu pudding place downstairs still had your favorite one.',
          ),
          NoteItemCopy(
            author: 'Xiaoman',
            timeLabel: 'Last night 9:18 PM',
            text: 'The wind was strong today. Zip your jacket on the way back.',
          ),
          NoteItemCopy(
            author: 'Ache',
            timeLabel: 'Sun 5:40 PM',
            text:
                'I still want to go back to that little place with you. The broth felt so warm.',
          ),
        ];

  String get spaceNameValue => isChinese ? '两个人的小屋' : 'Little Room for Two';
  String get inviteStatusValue => isChinese
      ? '邀请流程还没接真实账号，先保留结构位。'
      : 'Invite flow is still local-only for now.';
  String get sharedRulesValue => isChinese
      ? '日历和计划默认是共享的，随记默认只有作者自己能改。'
      : 'Calendar and plans are shared by default. Notes are editable only by their author.';
  String get relationshipDateValue =>
      isChinese ? '2025 年 10 月 5 日' : 'October 5, 2025';
  String get cyclePrivacyValue => isChinese
      ? '经期记录以后会进入日历，但默认只属于记录的人，明确开启后才共享。'
      : 'Cycle records will later appear in calendar, but they belong to the recorder unless sharing is explicitly enabled.';
  String get exportUnlinkValue => isChinese
      ? '导出和解绑先放在这里预留，真实行为等共享版本接入后再开放。'
      : 'Export and unlink stay here as placeholders until the shared version is wired.';
  DateTime get calendarPrototypeDisplayMonth => DateTime(2026, 6);
  DateTime get calendarPrototypeReferenceDate => DateTime(2026, 5, 27, 9);

  String get calendarOverviewTitle =>
      isChinese ? '这个月的有日期安排' : 'This month\'s dated plans';
  String get calendarOverviewSubtitle => isChinese
      ? '纪念日、约会和提醒，只要定了日期，就都放在这里。'
      : 'If it has a date, this is where anniversaries, dates, and reminders belong.';
  String get calendarOverviewCaption => isChinese
      ? '月视图、当天详情和近期事项都来自同一份样例日历。'
      : 'The month view, day details, and coming-up list all come from the same sample calendar.';
  String get calendarDetailsTitle =>
      isChinese ? '这一天有什么' : 'What is on this day';
  String get calendarDetailsHint => isChinese
      ? '只看当前选中日期，不混入别的内容。'
      : 'Only items for the selected date appear here.';
  String get calendarEmptyDayTitle =>
      isChinese ? '这一天先留白' : 'This day is still open';
  String get calendarEmptyDaySubtitle => isChinese
      ? '有明确日期的纪念日、约会或提醒，才会出现在这里。'
      : 'Only dated anniversaries, date plans, or reminders will show here.';
  String get calendarUpcomingTitle =>
      isChinese ? '近期事项' : 'Coming up soon';
  String get calendarUpcomingHint => isChinese
      ? '按时间顺序往后看，和上面的月历是同一批内容。'
      : 'The next few dated items, in order, from the same calendar data.';
  String get calendarComposerTitle =>
      isChinese ? '放进日历的内容' : 'What belongs in calendar';
  String get calendarComposerHint => isChinese
      ? '首版先只收纪念日、约会和提醒。'
      : 'For now, calendar only holds anniversaries, dates, and reminders.';
  String get calendarPeriodPlaceholderTitle =>
      isChinese ? '经期记录会后续接入' : 'Cycle records come later';
  String get calendarPeriodPlaceholderSubtitle => isChinese
      ? '经期记录之后也会放在日历里，但会单独分区，也不会默认共享。'
      : 'Cycle records will live here later too, but in a clearly separate area and never shared by default.';
  String get calendarRepeatYearlyLabel =>
      isChinese ? '每年重复' : 'Repeats yearly';
  String get calendarRepeatOnceLabel =>
      isChinese ? '单次安排' : 'One-time';
  String get calendarTodayLabel => isChinese ? '今天' : 'Today';
  String get calendarTomorrowLabel => isChinese ? '明天' : 'Tomorrow';

  String calendarTypeLabel(CalendarEntryType type) => switch (type) {
        CalendarEntryType.anniversary =>
          isChinese ? '纪念日' : 'Anniversary',
        CalendarEntryType.datePlan => isChinese ? '约会' : 'Date',
        CalendarEntryType.reminder => isChinese ? '提醒' : 'Reminder',
      };

  String calendarRepeatLabel(CalendarRepeatRule repeatRule) =>
      switch (repeatRule) {
        CalendarRepeatRule.none => calendarRepeatOnceLabel,
        CalendarRepeatRule.yearly => calendarRepeatYearlyLabel,
      };

  List<CalendarEntryData> get calendarPrototypeEntries => isChinese
      ? [
          CalendarEntryData(
            id: 'relationship-anniversary',
            type: CalendarEntryType.anniversary,
            title: '在一起纪念日',
            description: '晚上想去河边那家小店慢慢吃顿饭。',
            startsAt: DateTime(2025, 6, 6),
            repeatRule: CalendarRepeatRule.yearly,
          ),
          CalendarEntryData(
            id: 'friday-date-night',
            type: CalendarEntryType.datePlan,
            title: '周五约会夜',
            description: '电影还没定，但晚上 19:30 先留给我们。',
            startsAt: DateTime(2026, 5, 29, 19, 30),
            repeatRule: CalendarRepeatRule.none,
          ),
          CalendarEntryData(
            id: 'plant-reminder',
            type: CalendarEntryType.reminder,
            title: '给阳台植物浇水',
            description: '顺手看看要不要带一个新的小花盆回来。',
            startsAt: DateTime(2026, 5, 27, 20),
            repeatRule: CalendarRepeatRule.none,
          ),
        ]
      : [
          CalendarEntryData(
            id: 'relationship-anniversary',
            type: CalendarEntryType.anniversary,
            title: 'Relationship anniversary',
            description: 'A slow dinner by the riverside sounds right for that night.',
            startsAt: DateTime(2025, 6, 6),
            repeatRule: CalendarRepeatRule.yearly,
          ),
          CalendarEntryData(
            id: 'friday-date-night',
            type: CalendarEntryType.datePlan,
            title: 'Friday date night',
            description:
                'The movie can wait. 7:30 PM is already saved for the two of you.',
            startsAt: DateTime(2026, 5, 29, 19, 30),
            repeatRule: CalendarRepeatRule.none,
          ),
          CalendarEntryData(
            id: 'plant-reminder',
            type: CalendarEntryType.reminder,
            title: 'Water the balcony plants',
            description: 'Maybe bring back a new little pot while you are at it.',
            startsAt: DateTime(2026, 5, 27, 20),
            repeatRule: CalendarRepeatRule.none,
          ),
        ];

  List<CalendarEntryOccurrence> get calendarUpcomingEntries {
    final upcoming = [
      for (final entry in calendarPrototypeEntries)
        if (entry.nextOccurrenceFrom(calendarPrototypeReferenceDate)
            case final occurrence?)
          CalendarEntryOccurrence(entry: entry, occurrence: occurrence),
    ];

    upcoming.sort((left, right) => left.occurrence.compareTo(right.occurrence));
    return upcoming;
  }

  DateTime get calendarDefaultSelectedDate {
    final displayMonth = calendarPrototypeDisplayMonth;
    final inMonthEntries = [
      for (final item in calendarUpcomingEntries)
        if (item.occurrence.year == displayMonth.year &&
            item.occurrence.month == displayMonth.month)
          item,
    ];
    if (inMonthEntries.isNotEmpty) {
      return _dateOnly(inMonthEntries.first.occurrence);
    }

    final visibleDays = calendarVisibleDaysForMonth(displayMonth);
    final visibleEntries = [
      for (final item in calendarUpcomingEntries)
        if (visibleDays.any((day) => _sameDate(day, item.occurrence))) item,
    ];
    if (visibleEntries.isNotEmpty) {
      return _dateOnly(visibleEntries.first.occurrence);
    }

    return _dateOnly(displayMonth);
  }

  CalendarEntryOccurrence get calendarFeaturedEntry {
    final matches = entriesForCalendarDay(calendarDefaultSelectedDate);
    if (matches.isNotEmpty) {
      return matches.first;
    }

    return calendarUpcomingEntries.first;
  }

  CalendarItemCopy get calendarFeaturedItem =>
      calendarItemCopyForOccurrence(calendarFeaturedEntry);

  List<CalendarEntryOccurrence> entriesForCalendarDay(DateTime day) {
    final normalizedDay = _dateOnly(day);
    final matches = [
      for (final item in calendarUpcomingEntries)
        if (_sameDate(item.occurrence, normalizedDay)) item,
    ];

    matches.sort((left, right) => left.occurrence.compareTo(right.occurrence));
    return matches;
  }

  List<DateTime> calendarVisibleDaysForMonth(DateTime displayMonth) {
    final monthStart = DateTime(displayMonth.year, displayMonth.month);
    var gridStart = monthStart.subtract(Duration(days: monthStart.weekday - 1));

    if (_sameDate(gridStart, monthStart)) {
      gridStart = gridStart.subtract(const Duration(days: 7));
    }

    return List<DateTime>.generate(
      42,
      (index) => gridStart.add(Duration(days: index)),
    );
  }

  CalendarItemCopy calendarItemCopyForOccurrence(
    CalendarEntryOccurrence item, {
    bool includeWeekday = false,
  }) {
    return CalendarItemCopy(
      id: item.entry.id,
      title: item.entry.title,
      subtitle: item.entry.description,
      dateLabel: formatCalendarDate(
        item.occurrence,
        includeWeekday: includeWeekday,
        includeTime: item.showsTime,
      ),
      countdownLabel: formatCountdownLabel(
        item.occurrence,
        calendarPrototypeReferenceDate,
      ),
      typeLabel: calendarTypeLabel(item.entry.type),
    );
  }

  String formatCalendarMonthYear(DateTime date) {
    if (isChinese) {
      return '${date.year} 年 ${date.month} 月';
    }

    return '${_englishMonthNames[date.month - 1]} ${date.year}';
  }

  String formatCalendarDate(
    DateTime date, {
    bool includeWeekday = false,
    bool includeTime = false,
  }) {
    final buffer = StringBuffer();

    if (isChinese) {
      buffer.write('${date.month} 月 ${date.day} 日');
    } else {
      buffer.write('${_englishMonthNames[date.month - 1]} ${date.day}');
    }

    if (includeWeekday) {
      buffer.write(' · ${calendarWeekdayLabel(date.weekday)}');
    }

    if (includeTime) {
      buffer.write(isChinese ? ' ' : ', ');
      buffer.write(_formatTime(date));
    }

    return buffer.toString();
  }

  String calendarWeekdayLabel(int weekday) => isChinese
      ? _chineseWeekdayNames[weekday - 1]
      : _englishWeekdayNames[weekday - 1];

  String formatCountdownLabel(DateTime target, DateTime reference) {
    final difference = DateTime(
      target.year,
      target.month,
      target.day,
    ).difference(DateTime(reference.year, reference.month, reference.day)).inDays;

    if (difference <= 0) {
      return calendarTodayLabel;
    }

    if (difference == 1) {
      return calendarTomorrowLabel;
    }

    return isChinese ? '$difference 天后' : 'In $difference days';
  }

  DateTime _dateOnly(DateTime date) => DateTime(
    date.year,
    date.month,
    date.day,
  );

  bool _sameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static const List<String> _englishMonthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _englishWeekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _chineseWeekdayNames = [
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];
}

class CalendarItemCopy {
  const CalendarItemCopy({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.dateLabel,
    required this.countdownLabel,
    required this.typeLabel,
  });

  final String id;
  final String title;
  final String subtitle;
  final String dateLabel;
  final String countdownLabel;
  final String typeLabel;
}

class CalendarEntryOccurrence {
  const CalendarEntryOccurrence({
    required this.entry,
    required this.occurrence,
  });

  final CalendarEntryData entry;
  final DateTime occurrence;

  bool get showsTime => occurrence.hour != 0 || occurrence.minute != 0;
}

class PlanItemCopy {
  const PlanItemCopy({
    required this.title,
    required this.body,
    required this.statusLabel,
    required this.helperLabel,
  });

  final String title;
  final String body;
  final String statusLabel;
  final String helperLabel;
}

class NoteItemCopy {
  const NoteItemCopy({
    required this.author,
    required this.timeLabel,
    required this.text,
  });

  final String author;
  final String timeLabel;
  final String text;
}

enum CalendarEntryType { anniversary, datePlan, reminder }

enum CalendarRepeatRule { none, yearly }

class CalendarEntryData {
  const CalendarEntryData({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.startsAt,
    required this.repeatRule,
  });

  final String id;
  final CalendarEntryType type;
  final String title;
  final String description;
  final DateTime startsAt;
  final CalendarRepeatRule repeatRule;

  bool occursOn(DateTime day) {
    if (repeatRule == CalendarRepeatRule.yearly) {
      return day.month == startsAt.month && day.day == startsAt.day;
    }

    return day.year == startsAt.year && day.month == startsAt.month && day.day == startsAt.day;
  }

  DateTime? nextOccurrenceFrom(DateTime reference) {
    if (repeatRule == CalendarRepeatRule.none) {
      return startsAt.isBefore(reference) ? null : startsAt;
    }

    final thisYear = DateTime(
      reference.year,
      startsAt.month,
      startsAt.day,
      startsAt.hour,
      startsAt.minute,
    );

    if (!thisYear.isBefore(reference)) {
      return thisYear;
    }

    return DateTime(
      reference.year + 1,
      startsAt.month,
      startsAt.day,
      startsAt.hour,
      startsAt.minute,
    );
  }
}
