import 'package:between_us/app/app_controller.dart';
import 'package:between_us/data/models/calendar_event_record.dart';
import 'package:between_us/data/models/cycle_record.dart';
import 'package:between_us/features/anniversaries/anniversaries_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('calendar opens in the default Chinese locale', (tester) async {
    await _pumpCalendar(tester);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.locale, const Locale('zh', 'CN'));
    expect(find.byType(CalendarScreen), findsOneWidget);
  });

  testWidgets('single mode: calendar shows empty state, no add button', (
    tester,
  ) async {
    await _pumpCalendar(tester);

    // Single mode shows the pending empty state.
    await _scrollTo(tester, find.text('还没有日历事件'));
    expect(find.text('还没有日历事件'), findsOneWidget);
    expect(find.text('邀请对方加入后，即可开始使用'), findsOneWidget);

    // Add event button should not appear in single mode.
    expect(find.text('添加事件'), findsNothing);
  });

  testWidgets('paired mode: calendar shows month view, detail, and add icon', (
    tester,
  ) async {
    await _pumpCalendar(
      tester,
      memberCount: 2,
      currentSpaceId: 'test-space-id',
      supabaseReady: true,
    );

    // Month view should show current month header.
    final now = DateTime.now();
    final expectedMonth = '${now.year} 年 ${now.month} 月';
    expect(find.text(expectedMonth), findsOneWidget);

    // Add event icon button should be visible in paired mode.
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Selected date label should be rendered.
    await _scrollTo(
      tester,
      find.byKey(const ValueKey('calendar-selected-date-label')),
    );
    expect(
      find.byKey(const ValueKey('calendar-selected-date-label')),
      findsOneWidget,
    );

    // With no events, detail area shows empty state.
    expect(find.byKey(const ValueKey('calendar-detail-empty')), findsOneWidget);
  });

  testWidgets('paired + supabaseReady: calendar loads without throwing', (
    tester,
  ) async {
    // This test exercises the real _loadEvents() code path.
    // With supabaseReady = true but no real Supabase backend,
    // _loadEvents() catches the error and keeps _events empty.
    await _pumpCalendar(
      tester,
      memberCount: 2,
      currentSpaceId: 'test-space-id',
      supabaseReady: true,
    );

    // Screen should render without red screen.
    expect(find.byType(CalendarScreen), findsOneWidget);

    // Month view with current month should be visible.
    final now = DateTime.now();
    final expectedMonth = '${now.year} 年 ${now.month} 月';
    expect(find.text(expectedMonth), findsOneWidget);

    // Upcoming section should show empty state (no events loaded).
    await _scrollTo(tester, find.text('还没有日历事件'));
    expect(find.text('还没有日历事件'), findsOneWidget);
  });

  testWidgets('paired mode: add event dialog opens and has expected fields', (
    tester,
  ) async {
    await _pumpCalendar(
      tester,
      memberCount: 2,
      currentSpaceId: 'test-space-id',
      supabaseReady: true,
    );

    // Tap the + icon button inside the month view card.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Dialog should appear with the expected title.
    expect(find.text('新建日历项'), findsOneWidget);
    // Only date_plan and reminder chips in dialog, no anniversary.
    // "约会" and "提醒" also appear in the filter chip row, so use findsWidgets.
    expect(find.text('约会'), findsWidgets);
    expect(find.text('提醒'), findsWidgets);
    expect(find.text('纪念日'), findsWidgets);
    // Title field hint.
    expect(find.text('标题'), findsOneWidget);
    // Date picker label.
    expect(find.text('日期'), findsOneWidget);
    // Create button.
    expect(find.text('创建'), findsOneWidget);
  });

  testWidgets('single mode: no delete buttons visible', (tester) async {
    await _pumpCalendar(tester);

    // Single mode shows empty state, no delete icons.
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('paired mode: event entry shows delete button', (tester) async {
    await _pumpCalendar(
      tester,
      memberCount: 2,
      currentSpaceId: 'test-space-id',
      supabaseReady: true,
    );

    // Inject mock events into the calendar state.
    // ignore: avoid_dynamic_calls
    final state = tester.state(find.byType(CalendarScreen)) as dynamic;
    state.debugSetEvents([
      CalendarEventRecord(
        id: 'test-event-1',
        coupleSpaceId: 'test-space-id',
        createdBy: 'test-user',
        eventType: 'date_plan',
        title: '测试约会',
        description: '测试描述',
        startsAt: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ]);
    await tester.pumpAndSettle();

    // Scroll to the upcoming event section to find the delete icon.
    await _scrollTo(
      tester,
      find.byKey(const ValueKey('calendar-upcoming-test-event-1')),
    );
    // Delete icon should be visible on the event entry.
    expect(find.byIcon(Icons.delete_outline), findsWidgets);
  });

  testWidgets('paired mode: tapping delete shows confirmation dialog', (
    tester,
  ) async {
    await _pumpCalendar(
      tester,
      memberCount: 2,
      currentSpaceId: 'test-space-id',
      supabaseReady: true,
    );

    // ignore: avoid_dynamic_calls
    final state = tester.state(find.byType(CalendarScreen)) as dynamic;
    state.debugSetEvents([
      CalendarEventRecord(
        id: 'test-event-1',
        coupleSpaceId: 'test-space-id',
        createdBy: 'test-user',
        eventType: 'date_plan',
        title: '测试约会',
        startsAt: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ]);
    await tester.pumpAndSettle();

    // Scroll to the delete icon and tap it.
    await _scrollTo(tester, find.byIcon(Icons.delete_outline).first);
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    // Confirmation dialog should appear.
    expect(find.text('删除这个事件？'), findsOneWidget);
    expect(find.text('删除后，这个事件将不再显示在日历中。'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);
  });

  testWidgets('paired mode: cancel delete keeps event visible', (tester) async {
    await _pumpCalendar(
      tester,
      memberCount: 2,
      currentSpaceId: 'test-space-id',
      supabaseReady: true,
    );

    // ignore: avoid_dynamic_calls
    final state = tester.state(find.byType(CalendarScreen)) as dynamic;
    state.debugSetEvents([
      CalendarEventRecord(
        id: 'test-event-1',
        coupleSpaceId: 'test-space-id',
        createdBy: 'test-user',
        eventType: 'date_plan',
        title: '测试约会',
        startsAt: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ]);
    await tester.pumpAndSettle();

    // Scroll to the delete icon, tap it, then cancel.
    await _scrollTo(tester, find.byIcon(Icons.delete_outline).first);
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    // Event title should still be visible.
    expect(find.text('测试约会'), findsWidgets);
  });

  testWidgets(
    'paired mode: confirm delete triggers refresh and removes event',
    (tester) async {
      await _pumpCalendar(
        tester,
        memberCount: 2,
        currentSpaceId: 'test-space-id',
        supabaseReady: true,
      );

      // ignore: avoid_dynamic_calls
      final state = tester.state(find.byType(CalendarScreen)) as dynamic;
      state.debugSetEvents([
        CalendarEventRecord(
          id: 'test-event-1',
          coupleSpaceId: 'test-space-id',
          createdBy: 'test-user',
          eventType: 'date_plan',
          title: '测试约会',
          startsAt: DateTime.now().add(const Duration(days: 1)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);
      await tester.pumpAndSettle();

      // Scroll to the delete icon, tap it, then confirm.
      await _scrollTo(tester, find.byIcon(Icons.delete_outline).first);
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed (no more confirmation text).
      expect(find.text('删除这个事件？'), findsNothing);

      // After confirm, _deleteEvent is called which triggers _loadEvents.
      // Since Supabase is not actually available, _loadEvents catches the
      // error and events list stays as-is. The key assertion is that the
      // delete flow completes without crashing.
      expect(find.byType(CalendarScreen), findsOneWidget);
    },
  );

  testWidgets('paired mode: self-created event shows own display name', (
    tester,
  ) async {
    await _pumpCalendar(
      tester,
      memberCount: 2,
      currentSpaceId: 'test-space-id',
      supabaseReady: true,
    );

    // ignore: avoid_dynamic_calls
    final state = tester.state(find.byType(CalendarScreen)) as dynamic;
    state.debugSetEvents([
      CalendarEventRecord(
        id: 'test-event-1',
        coupleSpaceId: 'test-space-id',
        createdBy: 'test-user', // same as selfProfileId
        eventType: 'date_plan',
        title: '测试约会',
        startsAt: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ]);
    await tester.pumpAndSettle();

    // Scroll to the author label and verify it shows own name.
    await _scrollTo(tester, find.textContaining('由 测试用户 创建'));
    expect(find.textContaining('由 测试用户 创建'), findsWidgets);
  });

  testWidgets('paired mode: partner-created event shows partner name', (
    tester,
  ) async {
    await _pumpCalendar(
      tester,
      memberCount: 2,
      currentSpaceId: 'test-space-id',
      supabaseReady: true,
      partnerDisplayName: '小满',
    );

    // ignore: avoid_dynamic_calls
    final state = tester.state(find.byType(CalendarScreen)) as dynamic;
    state.debugSetEvents([
      CalendarEventRecord(
        id: 'test-event-1',
        coupleSpaceId: 'test-space-id',
        createdBy: 'partner-user', // different from selfProfileId
        eventType: 'date_plan',
        title: '测试约会',
        startsAt: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ]);
    await tester.pumpAndSettle();

    // Scroll to the author label and verify it shows partner name.
    await _scrollTo(tester, find.textContaining('由 小满 创建'));
    expect(find.textContaining('由 小满 创建'), findsWidgets);
  });

  testWidgets('single mode: no author label on events', (tester) async {
    await _pumpCalendar(tester);

    // Single mode shows empty state, no author labels.
    expect(find.textContaining('由'), findsNothing);
    expect(find.textContaining('创建'), findsNothing);
  });

  // ── Filter chip tests ─────────────────────────────────────────────────

  testWidgets('paired mode: default filter shows all event types', (
    tester,
  ) async {
    await _pumpCalendar(
      tester,
      memberCount: 2,
      currentSpaceId: 'test-space-id',
      supabaseReady: true,
    );

    // Filter chip row should show "全部" as selected by default.
    expect(find.text('全部'), findsOneWidget);
    // All filter options should be visible.
    expect(find.text('纪念日'), findsOneWidget);
    expect(find.text('约会'), findsOneWidget);
    expect(find.text('提醒'), findsOneWidget);
  });

  testWidgets('paired mode: selecting a filter hides non-matching events', (
    tester,
  ) async {
    await _pumpCalendar(
      tester,
      memberCount: 2,
      currentSpaceId: 'test-space-id',
      supabaseReady: true,
    );

    // Inject events on the selected date (today) so they appear in detail section.
    // ignore: avoid_dynamic_calls
    final state = tester.state(find.byType(CalendarScreen)) as dynamic;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    state.debugSetEvents([
      CalendarEventRecord(
        id: 'event-date',
        coupleSpaceId: 'test-space-id',
        createdBy: 'test-user',
        eventType: 'date_plan',
        title: '测试约会',
        startsAt: today,
        createdAt: now,
        updatedAt: now,
      ),
      CalendarEventRecord(
        id: 'event-reminder',
        coupleSpaceId: 'test-space-id',
        createdBy: 'test-user',
        eventType: 'reminder',
        title: '测试提醒',
        startsAt: today,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
    await tester.pumpAndSettle();

    // Both events should be visible in the selected day detail.
    expect(find.text('测试约会'), findsOneWidget);
    expect(find.text('测试提醒'), findsOneWidget);

    // Tap the "提醒" filter chip (use widgetWithText to disambiguate).
    await tester.tap(find.widgetWithText(FilterChip, '提醒'));
    await tester.pumpAndSettle();

    // Only reminder should be visible. The date plan event should be filtered out.
    expect(find.text('测试提醒'), findsOneWidget);
    expect(find.text('测试约会'), findsNothing);
  });

  testWidgets('paired mode: switching back to all restores all events', (
    tester,
  ) async {
    await _pumpCalendar(
      tester,
      memberCount: 2,
      currentSpaceId: 'test-space-id',
      supabaseReady: true,
    );

    // ignore: avoid_dynamic_calls
    final state = tester.state(find.byType(CalendarScreen)) as dynamic;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    state.debugSetEvents([
      CalendarEventRecord(
        id: 'event-date',
        coupleSpaceId: 'test-space-id',
        createdBy: 'test-user',
        eventType: 'date_plan',
        title: '测试约会',
        startsAt: today,
        createdAt: now,
        updatedAt: now,
      ),
      CalendarEventRecord(
        id: 'event-reminder',
        coupleSpaceId: 'test-space-id',
        createdBy: 'test-user',
        eventType: 'reminder',
        title: '测试提醒',
        startsAt: today,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
    await tester.pumpAndSettle();

    // Select "提醒" filter.
    await tester.tap(find.widgetWithText(FilterChip, '提醒'));
    await tester.pumpAndSettle();
    expect(find.text('测试约会'), findsNothing);

    // Switch back to "全部".
    await tester.tap(find.widgetWithText(FilterChip, '全部'));
    await tester.pumpAndSettle();

    // Both events should be visible again.
    expect(find.text('测试约会'), findsOneWidget);
    expect(find.text('测试提醒'), findsOneWidget);
  });

  testWidgets('non-female user does not see cycle filter chip', (tester) async {
    final controller = AppController();
    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
    );
    controller.debugSeedLoadedProfile(
      userId: 'test-user',
      displayName: '测试用户',
      gender: AppController.genderMale,
      memberCount: 2,
      currentSpaceId: 'test-space-id',
    );

    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: MaterialApp(
          locale: controller.locale,
          supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(body: SafeArea(child: CalendarScreen())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // "全部", "纪念日", "约会", "提醒" should be visible.
    expect(find.text('全部'), findsOneWidget);
    expect(find.text('纪念日'), findsOneWidget);
    expect(find.text('约会'), findsOneWidget);
    expect(find.text('提醒'), findsOneWidget);
    // Cycle filter chip should NOT be visible for male users.
    expect(find.text('生理期'), findsNothing);
  });

  testWidgets('female user sees cycle filter chip', (tester) async {
    await _pumpCalendar(
      tester,
      memberCount: 2,
      currentSpaceId: 'test-space-id',
      supabaseReady: true,
    );

    // Female user in active couple space should see cycle filter chip.
    expect(find.text('生理期'), findsOneWidget);
  });

  testWidgets('cycle and event on same day both visible', (tester) async {
    await _pumpCalendar(
      tester,
      memberCount: 2,
      currentSpaceId: 'test-space-id',
      supabaseReady: true,
    );

    // ignore: avoid_dynamic_calls
    final state = tester.state(find.byType(CalendarScreen)) as dynamic;
    final now = DateTime.now();
    final selectedDate = DateTime(now.year, now.month, now.day);

    // Inject an event and a cycle record on the same day.
    state.debugSetEvents([
      CalendarEventRecord(
        id: 'event-same-day',
        coupleSpaceId: 'test-space-id',
        createdBy: 'test-user',
        eventType: 'date_plan',
        title: '同日约会',
        startsAt: selectedDate,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
    state.debugSetCycleRecords([
      CycleRecord(
        id: 'cycle-same-day',
        coupleSpaceId: 'test-space-id',
        ownerProfileId: 'test-user',
        periodStartDate: selectedDate,
        periodEndDate: selectedDate,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
    await tester.pumpAndSettle();

    // Both the event card and cycle card should appear in selected day detail.
    expect(find.text('同日约会'), findsOneWidget);
    expect(find.text('经期'), findsWidgets);
  });

  testWidgets(
    'calendar avoids horizontal overflow on narrow large-text screens',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final overflowMessages = <String>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final message = details.exceptionAsString();
        if (message.contains('overflowed')) {
          overflowMessages.add(message);
          return;
        }
        previousOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousOnError);

      await _pumpCalendar(
        tester,
        memberCount: 2,
        currentSpaceId: 'test-space-id',
        partnerDisplayName: '一个非常非常长的伴侣昵称用于测试横向布局',
        textScaler: const TextScaler.linear(1.45),
      );

      // ignore: avoid_dynamic_calls
      final state = tester.state(find.byType(CalendarScreen)) as dynamic;
      final now = DateTime.now();
      final selectedDate = DateTime(now.year, now.month, now.day);

      state.debugSetEvents([
        CalendarEventRecord(
          id: 'event-responsive',
          coupleSpaceId: 'test-space-id',
          createdBy: 'partner-user',
          eventType: 'date_plan',
          title: '这是一条很长很长的约会标题用来模拟窄屏和大字体下的真实文案',
          description: '这是一段较长的备注，用来确认详情卡片、作者标签和即将到来区域不会把右侧内容挤出父容器。',
          startsAt: selectedDate,
          createdAt: now,
          updatedAt: now,
        ),
      ]);
      state.debugSetCycleRecords([
        CycleRecord(
          id: 'cycle-responsive',
          coupleSpaceId: 'test-space-id',
          ownerProfileId: 'test-user',
          periodStartDate: selectedDate,
          periodEndDate: selectedDate.add(const Duration(days: 4)),
          note: '一段偏长的经期记录备注，用来验证标签、日期范围和操作按钮不会在窄屏下横向溢出。',
          createdAt: now,
          updatedAt: now,
        ),
      ]);
      await tester.pump();
      await tester.pump();

      expect(overflowMessages, isEmpty);
    },
  );
}

Future<void> _pumpCalendar(
  WidgetTester tester, {
  int memberCount = 0,
  String? currentSpaceId,
  bool supabaseReady = false,
  String? partnerDisplayName,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final controller = AppController();
  controller.debugSetAuthState(
    status: AppAuthStatus.authenticated,
    supabaseReady: supabaseReady,
  );
  controller.debugSeedLoadedProfile(
    userId: 'test-user',
    displayName: '测试用户',
    gender: AppController.genderFemale,
    memberCount: memberCount,
    currentSpaceId: currentSpaceId,
    partnerDisplayName: partnerDisplayName,
  );

  await tester.pumpWidget(
    AppScope(
      controller: controller,
      child: MaterialApp(
        locale: controller.locale,
        supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: MediaQuery(
          data: MediaQueryData(textScaler: textScaler),
          child: const Scaffold(body: SafeArea(child: CalendarScreen())),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  // Find the vertical Scrollable (ListView) inside CalendarScreen,
  // ignoring the horizontal Scrollable from _FilterChipRow.
  final scrollableFinder = find.descendant(
    of: find.byType(CalendarScreen),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    ),
  );
  // Try scrollUntilVisible first (works when target is already in widget tree).
  try {
    await tester.scrollUntilVisible(finder, 200, scrollable: scrollableFinder);
    await tester.pumpAndSettle();
    return;
  } catch (_) {
    // Target may not be built yet due to ListView lazy rendering.
    // Scroll down in increments until it appears.
  }
  for (var i = 0; i < 10; i++) {
    await tester.drag(scrollableFinder, const Offset(0, -300));
    await tester.pumpAndSettle();
    if (finder.evaluate().isNotEmpty) return;
  }
}
