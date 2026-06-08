import 'package:between_us/app/app_controller.dart';
import 'package:between_us/app/between_us_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ─── Single mode: invite entry ────────────────────────────────────────

  testWidgets('single mode: Us screen shows invite entry (add avatar)', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      displayName: '小满',
      gender: AppController.genderFemale,
      memberCount: 1,
    );

    // Navigate to Us tab.
    await _navigateToUsTab(tester);

    // Single mode should show the add-avatar slot (invite entry).
    expect(find.byKey(const ValueKey('us-hero-single-slot')), findsOneWidget);
    expect(find.byKey(const ValueKey('us-hero-partner-slot')), findsNothing);
  });

  testWidgets('single mode: tapping invite entry navigates to invite page', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      displayName: '小满',
      gender: AppController.genderFemale,
      memberCount: 1,
    );

    // Navigate to Us tab.
    await _navigateToUsTab(tester);

    // Tap the add avatar to navigate to invite page.
    await tester.tap(find.byKey(const ValueKey('us-hero-single-slot')));
    await tester.pumpAndSettle();

    // Invite page should show the placeholder section.
    expect(
      find.byKey(const ValueKey('us-invite-placeholder-section')),
      findsOneWidget,
    );

    // Should show invite action buttons.
    expect(
      find.byKey(const ValueKey('us-space-invite-actions')),
      findsOneWidget,
    );

    // Generate invite code button.
    expect(find.text('生成邀请码'), findsOneWidget);

    // Enter invite code button.
    expect(find.text('输入邀请码加入'), findsOneWidget);
  });

  testWidgets('single mode: tapping enter invite code shows dialog', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      displayName: '小满',
      gender: AppController.genderFemale,
      memberCount: 1,
    );

    // Navigate to Us tab.
    await _navigateToUsTab(tester);

    // Tap the add avatar to navigate to invite page.
    await tester.tap(find.byKey(const ValueKey('us-hero-single-slot')));
    await tester.pumpAndSettle();

    // Tap the enter invite code button.
    await tester.tap(find.text('输入邀请码加入'));
    await tester.pumpAndSettle();

    // Dialog should appear with expected title.
    expect(find.text('输入邀请码'), findsOneWidget);

    // Dialog should have a hint text field.
    expect(find.text('请输入对方分享的邀请码'), findsOneWidget);

    // Dialog should have cancel and join buttons.
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('加入'), findsOneWidget);
  });

  testWidgets('single mode: invite code dialog cancel closes dialog', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      displayName: '小满',
      gender: AppController.genderFemale,
      memberCount: 1,
    );

    // Navigate to Us tab and open invite page.
    await _navigateToUsTab(tester);
    await tester.tap(find.byKey(const ValueKey('us-hero-single-slot')));
    await tester.pumpAndSettle();

    // Open the enter invite code dialog.
    await tester.tap(find.text('输入邀请码加入'));
    await tester.pumpAndSettle();

    // Dialog should be open.
    expect(find.text('输入邀请码'), findsOneWidget);

    // Tap cancel.
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    // Dialog should be closed.
    expect(find.text('输入邀请码'), findsNothing);
  });

  testWidgets('single mode: invite page shows invite placeholder description', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      displayName: '小满',
      gender: AppController.genderFemale,
      memberCount: 1,
    );

    // Navigate to Us tab and open invite page.
    await _navigateToUsTab(tester);
    await tester.tap(find.byKey(const ValueKey('us-hero-single-slot')));
    await tester.pumpAndSettle();

    // Invite page should show descriptive text.
    expect(find.text('先给 TA 留一个位置'), findsWidgets);
  });

  // ─── Paired mode: no invite entry ────────────────────────────────────

  testWidgets('paired mode: Us screen shows partner slot, not invite entry', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      displayName: '小满',
      gender: AppController.genderFemale,
      memberCount: 2,
      partnerDisplayName: '阿澈',
    );

    // Navigate to Us tab.
    await _navigateToUsTab(tester);

    // Paired mode shows partner slot, not single slot.
    expect(find.byKey(const ValueKey('us-hero-partner-slot')), findsOneWidget);
    expect(find.byKey(const ValueKey('us-hero-single-slot')), findsNothing);
  });

  testWidgets(
    'paired mode: tapping partner slot opens partner profile, not invite',
    (tester) async {
      await _pumpApp(
        tester,
        displayName: '小满',
        gender: AppController.genderFemale,
        memberCount: 2,
        partnerDisplayName: '阿澈',
      );

      // Navigate to Us tab.
      await _navigateToUsTab(tester);

      // Tap the partner avatar.
      await tester.tap(find.byKey(const ValueKey('us-hero-partner-slot')));
      await tester.pumpAndSettle();

      // Should navigate to partner profile, not invite page.
      expect(
        find.byKey(const ValueKey('us-partner-profile-section')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('us-invite-placeholder-section')),
        findsNothing,
      );

      // Partner name should be visible.
      expect(find.text('阿澈'), findsWidgets);
    },
  );

  testWidgets(
    'paired mode: partner screen shows generate code and enter code buttons',
    (tester) async {
      await _pumpApp(
        tester,
        displayName: '小满',
        gender: AppController.genderFemale,
        memberCount: 2,
        partnerDisplayName: '阿澈',
      );

      // Navigate to Us tab.
      await _navigateToUsTab(tester);

      // Tap the partner avatar.
      await tester.tap(find.byKey(const ValueKey('us-hero-partner-slot')));
      await tester.pumpAndSettle();

      // Partner screen shows paired content, not invite actions.
      expect(
        find.byKey(const ValueKey('us-partner-profile-section')),
        findsOneWidget,
      );

      // Should NOT show the invite action buttons.
      expect(
        find.byKey(const ValueKey('us-space-invite-actions')),
        findsNothing,
      );
    },
  );

  // ─── hasActiveCoupleSpace boundary ────────────────────────────────────

  test('hasActiveCoupleSpace is false when memberCount is 1', () {
    final controller = AppController();
    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      displayName: '小满',
      currentSpaceId: 'space-1',
      memberCount: 1,
    );

    expect(controller.hasActiveCoupleSpace, isFalse);
  });

  test(
    'hasActiveCoupleSpace is true when memberCount >= 2 and spaceId set',
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
    },
  );

  test('hasActiveCoupleSpace is false when currentSpaceId is null', () {
    final controller = AppController();
    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      displayName: '小满',
      memberCount: 2,
    );

    expect(controller.hasActiveCoupleSpace, isFalse);
  });
}

// ─── Test helpers ──────────────────────────────────────────────────────

Future<void> _pumpApp(
  WidgetTester tester, {
  required String displayName,
  String? gender,
  int memberCount = 0,
  String? partnerDisplayName,
  String? currentSpaceId,
}) async {
  final controller = AppController();
  controller.debugSetAuthState(
    status: AppAuthStatus.authenticated,
    supabaseReady: false,
    displayName: displayName,
    gender: gender ?? AppController.genderFemale,
    memberCount: memberCount,
    partnerDisplayName: partnerDisplayName,
    currentSpaceId:
        currentSpaceId ?? (memberCount >= 2 ? 'test-space-id' : null),
  );
  controller.debugSeedLoadedProfile(
    userId: 'test-user',
    displayName: displayName,
    gender: gender ?? AppController.genderFemale,
    memberCount: memberCount,
    currentSpaceId:
        currentSpaceId ?? (memberCount >= 2 ? 'test-space-id' : null),
    partnerDisplayName: partnerDisplayName,
  );

  await tester.pumpWidget(BetweenUsApp(controller: controller));
  await tester.pumpAndSettle();
}

Future<void> _navigateToUsTab(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(Icons.favorite_border),
    ),
  );
  await tester.pumpAndSettle();
}
