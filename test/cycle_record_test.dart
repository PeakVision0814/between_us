import 'package:between_us/app/app_controller.dart';
import 'package:between_us/data/models/cycle_record.dart';
import 'package:between_us/features/anniversaries/anniversaries_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('single mode: cycle feature is unavailable', (tester) async {
    await _pumpCalendar(
      tester,
      gender: AppController.genderFemale,
      memberCount: 1,
    );

    expect(find.byType(CalendarScreen), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.text('经期'), findsNothing);
  });

  testWidgets('paired female user can open cycle creation dialog', (
    tester,
  ) async {
    await _pumpCalendar(
      tester,
      gender: AppController.genderFemale,
      memberCount: 2,
      currentSpaceId: 'space-1',
      supabaseReady: true,
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('经期'), findsOneWidget);
    await tester.tap(find.text('经期'));
    await tester.pumpAndSettle();

    expect(find.text('记录经期'), findsOneWidget);
    expect(find.text('开始日期'), findsOneWidget);
    expect(find.text('结束日期'), findsOneWidget);
  });

  testWidgets('paired male user does not see cycle creation entry', (
    tester,
  ) async {
    await _pumpCalendar(
      tester,
      gender: AppController.genderMale,
      memberCount: 2,
      currentSpaceId: 'space-1',
      supabaseReady: true,
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // "约会" and "提醒" appear in both filter chips and dialog ChoiceChips.
    expect(find.text('约会'), findsWidgets);
    expect(find.text('提醒'), findsWidgets);
    expect(find.text('经期'), findsNothing);
  });

  testWidgets('cycle marker and detail are shown on calendar', (tester) async {
    final today = DateUtils.dateOnly(DateTime.now());
    await _pumpCalendar(
      tester,
      gender: AppController.genderFemale,
      memberCount: 2,
      currentSpaceId: 'space-1',
      supabaseReady: true,
    );

    final state = tester.state(find.byType(CalendarScreen)) as dynamic;
    // ignore: avoid_dynamic_calls
    state.debugSetCycleRecords([
      _cycleRecord(
        ownerProfileId: 'test-user',
        start: today,
        end: today.add(const Duration(days: 2)),
      ),
    ]);
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.byKey(const ValueKey('cycle-detail-cycle-1')));
    expect(find.byKey(const ValueKey('cycle-detail-cycle-1')), findsOneWidget);
    expect(find.text('经期'), findsOneWidget);
    expect(find.text('仅自己可见'), findsNothing);
    expect(find.text('已共享给伴侣'), findsNothing);
  });

  testWidgets('overlapping owner cycle records render as one date range', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    await _pumpCalendar(
      tester,
      gender: AppController.genderFemale,
      memberCount: 2,
      currentSpaceId: 'space-1',
      supabaseReady: true,
    );

    final state = tester.state(find.byType(CalendarScreen)) as dynamic;
    // ignore: avoid_dynamic_calls
    state.debugSetCycleRecords([
      _cycleRecord(
        ownerProfileId: 'test-user',
        start: today,
        end: today.add(const Duration(days: 2)),
      ),
    ]);
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.byKey(const ValueKey('cycle-detail-cycle-1')));
    expect(find.byKey(const ValueKey('cycle-detail-cycle-1')), findsOneWidget);
    expect(find.text('轻微不适'), findsOneWidget);
  });

  testWidgets(
    'shared cycle record is visible in partner view without owner actions',
    (tester) async {
      final today = DateUtils.dateOnly(DateTime.now());
      await _pumpCalendar(
        tester,
        gender: AppController.genderMale,
        memberCount: 2,
        currentSpaceId: 'space-1',
        supabaseReady: true,
      );

      final state = tester.state(find.byType(CalendarScreen)) as dynamic;
      // ignore: avoid_dynamic_calls
      state.debugSetCycleRecords([
        _cycleRecord(
          ownerProfileId: 'partner-user',
          start: today,
          sharedWithPartner: true,
        ),
      ]);
      await tester.pumpAndSettle();

      await _scrollTo(
        tester,
        find.byKey(const ValueKey('cycle-detail-cycle-1')),
      );
      expect(
        find.byKey(const ValueKey('cycle-detail-cycle-1')),
        findsOneWidget,
      );
      expect(find.text('伴侣的经期记录'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    },
  );

  testWidgets('private cycle record is not visible in partner view', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    await _pumpCalendar(
      tester,
      gender: AppController.genderMale,
      memberCount: 2,
      currentSpaceId: 'space-1',
      supabaseReady: true,
    );

    final state = tester.state(find.byType(CalendarScreen)) as dynamic;
    // ignore: avoid_dynamic_calls
    state.debugSetCycleRecords([
      _cycleRecord(
        ownerProfileId: 'partner-user',
        start: today,
        sharedWithPartner: false,
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cycle-detail-cycle-1')), findsNothing);
    expect(find.text('经期'), findsNothing);
  });

  testWidgets('profile sharing off hides shared cycle record in partner view', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    await _pumpCalendar(
      tester,
      gender: AppController.genderMale,
      memberCount: 2,
      currentSpaceId: 'space-1',
      supabaseReady: true,
    );

    final state = tester.state(find.byType(CalendarScreen)) as dynamic;
    // ignore: avoid_dynamic_calls
    state.debugSetCycleRecords([
      _cycleRecord(
        ownerProfileId: 'partner-user',
        start: today,
        sharedWithPartner: true,
        ownerCycleSharingEnabled: false,
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cycle-detail-cycle-1')), findsNothing);
    expect(find.text('经期'), findsNothing);
  });
}

CycleRecord _cycleRecord({
  required String ownerProfileId,
  required DateTime start,
  DateTime? end,
  bool sharedWithPartner = false,
  bool ownerCycleSharingEnabled = true,
}) {
  final now = DateTime.now();
  return CycleRecord(
    id: 'cycle-1',
    coupleSpaceId: 'space-1',
    ownerProfileId: ownerProfileId,
    periodStartDate: start,
    periodEndDate: end,
    note: '轻微不适',
    sharedWithPartner: sharedWithPartner,
    ownerCycleSharingEnabled: ownerCycleSharingEnabled,
    createdAt: now,
    updatedAt: now,
  );
}

Future<void> _pumpCalendar(
  WidgetTester tester, {
  required String gender,
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
    gender: gender,
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
  final scrollableFinder = find.descendant(
    of: find.byType(CalendarScreen),
    matching: find.byType(Scrollable),
  );
  try {
    await tester.scrollUntilVisible(finder, 200, scrollable: scrollableFinder);
    await tester.pumpAndSettle();
    return;
  } catch (_) {}
  for (var i = 0; i < 10; i++) {
    await tester.drag(scrollableFinder, const Offset(0, -300));
    await tester.pumpAndSettle();
    if (finder.evaluate().isNotEmpty) return;
  }
}
