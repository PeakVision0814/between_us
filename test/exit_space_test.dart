import 'package:between_us/app/app_controller.dart';
import 'package:between_us/features/settings/settings_screen.dart'
    show SpaceStatusScreen, ExitRequestSnapshot;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ─── Exit button visibility ──────────────────────────────────────────

  testWidgets(
    'paired mode: space status screen shows exit button',
    (tester) async {
      await _pumpSpaceStatus(tester);

      // Should show exit button.
      expect(
        find.byKey(const ValueKey('exit-space-request-button')),
        findsOneWidget,
      );
      expect(find.text('退出双人空间'), findsOneWidget);

      // Should NOT show waiting or partner-request state.
      expect(find.byKey(const ValueKey('exit-space-waiting')), findsNothing);
      expect(
        find.byKey(const ValueKey('exit-space-partner-request')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'paired mode: space status shows active status and sharing info',
    (tester) async {
      await _pumpSpaceStatus(tester);

      // Should show active status.
      expect(find.text('双人空间已开启'), findsWidgets);

      // Should show sharing info with partner name.
      expect(find.text('与 阿澈 共享中'), findsOneWidget);

      // Should show return-to-single hint.
      expect(find.text('退出后双方回到单人态'), findsOneWidget);
    },
  );

  // ─── Exit confirmation dialogs ───────────────────────────────────────

  testWidgets(
    'tapping exit button shows first confirmation dialog with warning',
    (tester) async {
      await _pumpSpaceStatus(tester);

      // Tap the exit button.
      await tester.tap(find.byKey(const ValueKey('exit-space-request-button')));
      await tester.pump(); // Let first dialog appear.

      // First confirmation dialog: strong warning.
      expect(find.text('退出双人空间'), findsWidgets); // title in dialog
      // Warning body appears in both the dialog and the exit section behind it.
      expect(
        find.textContaining('退出后，你们双方都会回到单人态'),
        findsWidgets,
      );
      expect(find.textContaining('计划、随记、日历数据不会被删除'), findsWidgets);

      // Dialog should have cancel and confirm buttons.
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('确认退出'), findsOneWidget);
    },
  );

  testWidgets(
    'cancel in first exit confirmation dialog dismisses it',
    (tester) async {
      await _pumpSpaceStatus(tester);

      // Tap the exit button.
      await tester.tap(find.byKey(const ValueKey('exit-space-request-button')));
      await tester.pump();

      // First dialog should be open.
      expect(find.text('确认退出'), findsOneWidget);

      // Tap cancel.
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      // Dialog should be closed. Back to the space status screen.
      expect(find.text('确认退出'), findsNothing);

      // Exit button should still be visible (no state change).
      expect(
        find.byKey(const ValueKey('exit-space-request-button')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'first confirm opens second confirmation dialog',
    (tester) async {
      await _pumpSpaceStatus(tester);

      // Tap the exit button.
      await tester.tap(find.byKey(const ValueKey('exit-space-request-button')));
      await tester.pump();

      // Confirm the first dialog.
      await tester.tap(find.text('确认退出'));
      await tester.pump(); // Let first dialog close.
      await tester.pump(); // Let second dialog appear.

      // Second confirmation dialog should appear.
      expect(find.text('确认退出'), findsWidgets); // title + button
      // Second dialog body.
      expect(
        find.textContaining('确定要发起退出双人空间的请求吗'),
        findsOneWidget,
      );

      // Should have cancel and exit buttons.
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('退出双人空间'), findsWidgets); // dialog button + original
    },
  );

  testWidgets(
    'cancel in second exit confirmation dialog dismisses it',
    (tester) async {
      await _pumpSpaceStatus(tester);

      // Tap the exit button.
      await tester.tap(find.byKey(const ValueKey('exit-space-request-button')));
      await tester.pump();

      // Confirm the first dialog.
      await tester.tap(find.text('确认退出'));
      await tester.pump();
      await tester.pump();

      // Second dialog should be open.
      expect(find.text('确认退出'), findsWidgets);

      // Tap cancel in the second dialog.
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      // Dialog should be closed.
      // Exit button should still be visible.
      expect(
        find.byKey(const ValueKey('exit-space-request-button')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'both confirmations trigger exit request and show waiting state',
    (tester) async {
      await _pumpSpaceStatus(tester);

      // Tap the exit button.
      await tester.tap(find.byKey(const ValueKey('exit-space-request-button')));
      await tester.pump();

      // Confirm the first dialog.
      await tester.tap(find.text('确认退出'));
      await tester.pump();
      await tester.pump();

      // Confirm the second dialog (tap the FilledButton "退出双人空间").
      await tester.tap(find.byType(FilledButton).last);
      await tester.pump(); // Let second dialog close.
      await tester.pump(); // Let snackbar and state update appear.

      // After confirmations, should transition to waiting state.
      expect(find.byKey(const ValueKey('exit-space-waiting')), findsOneWidget);
      // Text appears in both the waiting widget and a snackbar.
      expect(find.text('已发起退出请求，等待对方确认'), findsWidgets);
    },
  );

  // ─── Self-requested waiting state ────────────────────────────────────

  testWidgets(
    'self-requested exit shows waiting state',
    (tester) async {
      await _pumpSpaceStatus(
        tester,
        initialExitRequest: const ExitRequestSnapshot(
          requestId: 'req-1',
          requestedBy: 'user-a-id', // self
        ),
      );

      // Should show waiting state.
      expect(find.byKey(const ValueKey('exit-space-waiting')), findsOneWidget);
      expect(find.text('已发起退出请求，等待对方确认'), findsOneWidget);

      // Should NOT show exit button or partner-request.
      expect(
        find.byKey(const ValueKey('exit-space-request-button')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('exit-space-partner-request')),
        findsNothing,
      );
    },
  );

  // ─── Partner-requested state ─────────────────────────────────────────

  testWidgets(
    'partner-requested exit shows approve button',
    (tester) async {
      await _pumpSpaceStatus(
        tester,
        initialExitRequest: const ExitRequestSnapshot(
          requestId: 'req-1',
          requestedBy: 'user-b-id', // partner
        ),
      );

      // Should show partner request text.
      expect(
        find.byKey(const ValueKey('exit-space-partner-request')),
        findsOneWidget,
      );
      expect(find.text('对方请求退出双人空间'), findsOneWidget);

      // Should show approve button.
      expect(
        find.byKey(const ValueKey('exit-space-approve-button')),
        findsOneWidget,
      );
      expect(find.text('同意退出'), findsOneWidget);

      // Should NOT show exit button or waiting state.
      expect(
        find.byKey(const ValueKey('exit-space-request-button')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('exit-space-waiting')), findsNothing);
    },
  );

  testWidgets(
    'tapping approve shows confirmation dialog',
    (tester) async {
      await _pumpSpaceStatus(
        tester,
        initialExitRequest: const ExitRequestSnapshot(
          requestId: 'req-1',
          requestedBy: 'user-b-id',
        ),
      );

      // Tap approve button.
      await tester.tap(find.byKey(const ValueKey('exit-space-approve-button')));
      await tester.pump(); // Let dialog appear.

      // Confirmation dialog should appear.
      expect(find.text('确认同意退出'), findsOneWidget);
      expect(
        find.textContaining('同意后，双人空间将关闭'),
        findsOneWidget,
      );

      // Should have cancel and approve buttons.
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('同意退出'), findsWidgets); // dialog button + original
    },
  );

  testWidgets(
    'cancel in approve dialog dismisses it',
    (tester) async {
      await _pumpSpaceStatus(
        tester,
        initialExitRequest: const ExitRequestSnapshot(
          requestId: 'req-1',
          requestedBy: 'user-b-id',
        ),
      );

      // Tap approve button.
      await tester.tap(find.byKey(const ValueKey('exit-space-approve-button')));
      await tester.pump();

      // Dialog should be open.
      expect(find.text('确认同意退出'), findsOneWidget);

      // Tap cancel.
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      // Dialog should be closed.
      expect(find.text('确认同意退出'), findsNothing);

      // Approve button should still be visible.
      expect(
        find.byKey(const ValueKey('exit-space-approve-button')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'confirming approve triggers exit and shows success',
    (tester) async {
      var approveCalled = false;

      await _pumpSpaceStatus(
        tester,
        initialExitRequest: const ExitRequestSnapshot(
          requestId: 'req-1',
          requestedBy: 'user-b-id',
        ),
        onApproveExit: (_) async {
          approveCalled = true;
          return true;
        },
      );

      // Tap approve button.
      await tester.tap(find.byKey(const ValueKey('exit-space-approve-button')));
      await tester.pump(); // Let dialog appear.

      // Confirm by tapping the FilledButton in the dialog.
      await tester.tap(find.byType(FilledButton).last);
      await tester.pump(); // Let dialog close.
      await tester.pump(); // Let snackbar appear.

      // Verify callback was called.
      expect(approveCalled, isTrue);

      // Should show success snackbar.
      expect(find.text('已退出双人空间'), findsOneWidget);
    },
  );

  // ─── currentSpaceId boundary ─────────────────────────────────────────

  test(
    'hasActiveCoupleSpace requires both memberCount >= 2 and currentSpaceId',
    () {
      final controller = AppController();
      controller.debugSetAuthState(
        status: AppAuthStatus.authenticated,
        supabaseReady: true,
        displayName: '小满',
        currentSpaceId: 'space-1',
        memberCount: 2,
        partnerDisplayName: '阿澈',
      );

      expect(controller.hasActiveCoupleSpace, isTrue);
      expect(controller.currentSpaceId, 'space-1');
      expect(controller.memberCount, 2);
    },
  );

  test(
    'hasActiveCoupleSpace is false when memberCount < 2 even with spaceId',
    () {
      final controller = AppController();
      controller.debugSetAuthState(
        status: AppAuthStatus.authenticated,
        supabaseReady: true,
        displayName: '小满',
        currentSpaceId: 'space-1',
        memberCount: 1,
      );

      expect(controller.hasActiveCoupleSpace, isFalse);
    },
  );
}

// ─── Test helpers ──────────────────────────────────────────────────────

Future<void> _pumpSpaceStatus(
  WidgetTester tester, {
  ExitRequestSnapshot? initialExitRequest,
  Future<String?> Function()? onRequestExit,
  Future<bool> Function(String requestId)? onApproveExit,
}) async {
  final controller = AppController();
  controller.debugSetAuthState(
    status: AppAuthStatus.authenticated,
    supabaseReady: true,
    displayName: '小满',
    gender: AppController.genderFemale,
    selfProfileId: 'user-a-id',
    currentSpaceId: 'space-1',
    memberCount: 2,
    partnerDisplayName: '阿澈',
  );

  await tester.pumpWidget(
    MaterialApp(
      locale: controller.locale,
      supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AppScope(
        controller: controller,
        child: SpaceStatusScreen(
          controller: controller,
          partnerName: '阿澈',
          initialExitRequest: initialExitRequest,
          onRequestExit: onRequestExit ?? () async => 'new-request-id',
          onApproveExit: onApproveExit ?? (_) async => true,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
