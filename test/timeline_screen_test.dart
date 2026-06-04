import 'package:between_us/app/app_controller.dart';
import 'package:between_us/features/timeline/timeline_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ─── Single mode tests ────────────────────────────────────────────────

  testWidgets(
    'single mode: plans page shows empty state, no create button',
    (tester) async {
      await _pumpTimeline(tester);

      // Single mode shows the pending partner empty state.
      expect(find.text('还没有计划'), findsOneWidget);
      expect(find.text('邀请对方加入后，即可开始使用'), findsOneWidget);

      // Create button should not appear in single mode.
      expect(find.text('加一个计划'), findsNothing);
    },
  );

  testWidgets(
    'single mode: notes tab shows empty state, no write button',
    (tester) async {
      await _pumpTimeline(tester);

      // Switch to notes mode.
      await tester.tap(find.text('随记'));
      await tester.pumpAndSettle();

      // Single mode shows the pending partner empty state for notes.
      expect(find.text('还没有随记'), findsOneWidget);
      expect(find.text('邀请对方加入后，即可开始使用'), findsOneWidget);

      // Write button should not appear in single mode.
      expect(find.text('写随记'), findsNothing);
    },
  );

  testWidgets('single mode: mode toggle is visible', (tester) async {
    await _pumpTimeline(tester);

    // Mode toggle should show both plans and notes tabs.
    expect(find.text('计划'), findsWidgets); // toggle + section header
    expect(find.text('随记'), findsOneWidget); // toggle
  });

  testWidgets(
    'single mode: mode lead card shows plan mode title',
    (tester) async {
      await _pumpTimeline(tester);

      // Default mode is plan, so lead card shows plan title.
      expect(find.text('想做的事，先记在这里'), findsOneWidget);
    },
  );

  testWidgets(
    'single mode: switching to notes mode shows note lead title',
    (tester) async {
      await _pumpTimeline(tester);

      // Switch to notes mode.
      await tester.tap(find.text('随记'));
      await tester.pumpAndSettle();

      expect(find.text('随手留一点，给彼此看看'), findsOneWidget);
    },
  );

  // ─── Paired mode tests ───────────────────────────────────────────────

  testWidgets(
    'paired mode: plans page shows empty state and create button',
    (tester) async {
      await _pumpTimeline(
        tester,
        memberCount: 2,
        currentSpaceId: 'test-space-id',
      );

      // Plans section header should be visible.
      expect(find.text('计划'), findsWidgets);

      // Empty state for plans (Supabase not available, so list is empty).
      expect(find.text('还没有计划'), findsOneWidget);

      // Create button should be visible in paired mode.
      expect(find.text('加一个计划'), findsOneWidget);
    },
  );

  testWidgets(
    'paired mode: notes tab shows empty state and write button',
    (tester) async {
      await _pumpTimeline(
        tester,
        memberCount: 2,
        currentSpaceId: 'test-space-id',
      );

      // Switch to notes mode.
      await tester.tap(find.text('随记'));
      await tester.pumpAndSettle();

      // Empty state for notes.
      expect(find.text('还没有随记'), findsOneWidget);

      // Write button should be visible in paired mode.
      expect(find.text('写随记'), findsOneWidget);
    },
  );

  testWidgets(
    'paired mode: tapping create plan opens dialog with expected fields',
    (tester) async {
      await _pumpTimeline(
        tester,
        memberCount: 2,
        currentSpaceId: 'test-space-id',
      );

      // Tap the create plan button.
      await tester.tap(find.text('加一个计划'));
      await tester.pumpAndSettle();

      // Dialog should appear with the expected title.
      expect(find.text('加一个计划'), findsWidgets); // button + dialog title

      // Title field hint.
      expect(find.text('想做什么...'), findsOneWidget);

      // Description field hint.
      expect(find.text('补充说明（可选）'), findsOneWidget);

      // Create button in dialog.
      expect(find.text('创建'), findsOneWidget);

      // Cancel button in dialog.
      expect(find.text('取消'), findsOneWidget);
    },
  );

  testWidgets(
    'paired mode: tapping write note opens dialog with expected fields',
    (tester) async {
      await _pumpTimeline(
        tester,
        memberCount: 2,
        currentSpaceId: 'test-space-id',
      );

      // Switch to notes mode.
      await tester.tap(find.text('随记'));
      await tester.pumpAndSettle();

      // Tap the write note button.
      await tester.tap(find.text('写随记'));
      await tester.pumpAndSettle();

      // Dialog should appear with the expected title.
      expect(find.text('写随记'), findsWidgets); // button + dialog title

      // Content field hint.
      expect(find.text('想到什么就留一点...'), findsOneWidget);

      // Send button in dialog.
      expect(find.text('发送'), findsOneWidget);

      // Cancel button in dialog.
      expect(find.text('取消'), findsOneWidget);
    },
  );

  testWidgets(
    'paired mode: create plan dialog cancel closes dialog',
    (tester) async {
      await _pumpTimeline(
        tester,
        memberCount: 2,
        currentSpaceId: 'test-space-id',
      );

      // Tap the create plan button.
      await tester.tap(find.text('加一个计划'));
      await tester.pumpAndSettle();

      // Dialog should be open.
      expect(find.text('想做什么...'), findsOneWidget);

      // Tap cancel.
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      // Dialog should be closed.
      expect(find.text('想做什么...'), findsNothing);
    },
  );

  testWidgets(
    'paired mode: mode switch hint is visible',
    (tester) async {
      await _pumpTimeline(
        tester,
        memberCount: 2,
        currentSpaceId: 'test-space-id',
      );

      // In plan mode, the switch-to-notes hint should be visible.
      expect(find.text('看看随记'), findsOneWidget);
    },
  );

  testWidgets(
    'paired mode: switching to notes shows switch-to-plans hint',
    (tester) async {
      await _pumpTimeline(
        tester,
        memberCount: 2,
        currentSpaceId: 'test-space-id',
      );

      // Switch to notes mode.
      await tester.tap(find.text('随记'));
      await tester.pumpAndSettle();

      // In notes mode, the switch-to-plans hint should be visible.
      expect(find.text('看看计划'), findsOneWidget);
    },
  );

  testWidgets(
    'paired mode: plan card author label uses resolveNoteAuthorName',
    (tester) async {
      // The resolveNoteAuthorName function is tested directly in
      // widget_test.dart. Here we verify that paired mode with partner name
      // renders without errors (the FutureBuilder catches Supabase errors
      // and shows empty state).
      await _pumpTimeline(
        tester,
        memberCount: 2,
        currentSpaceId: 'test-space-id',
        partnerDisplayName: '阿澈',
        selfProfileId: 'test-user',
      );

      // Plans section should be visible with create button.
      expect(find.text('加一个计划'), findsOneWidget);

      // Empty state visible (Supabase not available).
      expect(find.text('还没有计划'), findsOneWidget);
    },
  );

  testWidgets(
    'paired mode: note section renders without errors',
    (tester) async {
      await _pumpTimeline(
        tester,
        memberCount: 2,
        currentSpaceId: 'test-space-id',
        partnerDisplayName: '阿澈',
        selfProfileId: 'test-user',
      );

      // Switch to notes mode.
      await tester.tap(find.text('随记'));
      await tester.pumpAndSettle();

      // Notes section should be visible with write button.
      expect(find.text('写随记'), findsOneWidget);

      // Empty state visible (Supabase not available).
      expect(find.text('还没有随记'), findsOneWidget);
    },
  );

  testWidgets('single mode: no author labels visible', (tester) async {
    await _pumpTimeline(tester);

    // Single mode shows empty state, no author labels.
    expect(find.textContaining('由'), findsNothing);
    expect(find.textContaining('创建'), findsNothing);
  });
}

// ─── Test helpers ──────────────────────────────────────────────────────

Future<void> _pumpTimeline(
  WidgetTester tester, {
  int memberCount = 0,
  String? currentSpaceId,
  String? selfProfileId,
  String? partnerDisplayName,
  PlansNotesMode mode = PlansNotesMode.overview,
}) async {
  final controller = AppController();
  controller.debugSetAuthState(
    status: AppAuthStatus.authenticated,
    supabaseReady: false, // Avoid Supabase realtime subscription setup.
  );
  controller.debugSeedLoadedProfile(
    userId: selfProfileId ?? 'test-user',
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
        home: Scaffold(
          body: SafeArea(child: PlansNotesScreen(mode: mode)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
