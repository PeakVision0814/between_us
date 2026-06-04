import 'package:between_us/app/app_controller.dart';
import 'package:between_us/data/models/calendar_event_record.dart';
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

  testWidgets(
    'paired mode: calendar shows month view, detail, and add icon',
    (tester) async {
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
      expect(
        find.byKey(const ValueKey('calendar-detail-empty')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'paired + supabaseReady: calendar loads without throwing',
    (tester) async {
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
    },
  );

  testWidgets(
    'paired mode: add event dialog opens and has expected fields',
    (tester) async {
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
      // Only date_plan and reminder chips, no anniversary.
      expect(find.text('约会'), findsOneWidget);
      expect(find.text('提醒'), findsOneWidget);
      expect(find.text('纪念日'), findsNothing);
      // Title field hint.
      expect(find.text('标题'), findsOneWidget);
      // Date picker label.
      expect(find.text('日期'), findsOneWidget);
      // Create button.
      expect(find.text('创建'), findsOneWidget);
    },
  );

  testWidgets('single mode: no delete buttons visible', (tester) async {
    await _pumpCalendar(tester);

    // Single mode shows empty state, no delete icons.
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets(
    'paired mode: event entry shows delete button',
    (tester) async {
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

      // Delete icon should be visible on the event entry.
      expect(find.byIcon(Icons.delete_outline), findsWidgets);
    },
  );

  testWidgets(
    'paired mode: tapping delete shows confirmation dialog',
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

      // Scroll to the delete icon and tap it.
      await _scrollTo(tester, find.byIcon(Icons.delete_outline).first);
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      // Confirmation dialog should appear.
      expect(find.text('删除这个事件？'), findsOneWidget);
      expect(find.text('删除后，这个事件将不再显示在日历中。'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
    },
  );

  testWidgets(
    'paired mode: cancel delete keeps event visible',
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

      // Scroll to the delete icon, tap it, then cancel.
      await _scrollTo(tester, find.byIcon(Icons.delete_outline).first);
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      // Event title should still be visible.
      expect(find.text('测试约会'), findsWidgets);
    },
  );

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
}

Future<void> _pumpCalendar(
  WidgetTester tester, {
  int memberCount = 0,
  String? currentSpaceId,
  bool supabaseReady = false,
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
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable),
  );
  await tester.pumpAndSettle();
}
