import 'dart:async';

import 'package:between_us/app/app_controller.dart';
import 'package:between_us/app/between_us_app.dart';
import 'package:between_us/features/auth/email_register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'unauthenticated users see the email OTP gate instead of the app shell',
    (tester) async {
      await _pumpApp(
        tester,
        authStatus: AppAuthStatus.unauthenticated,
        supabaseReady: true,
      );

      expect(find.byKey(const ValueKey('auth-email-field')), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    },
  );

  testWidgets('sign-in screen can navigate to register screen', (tester) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.unauthenticated,
      supabaseReady: true,
    );

    await tester.tap(find.byKey(const ValueKey('auth-go-register-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-register-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-email-field')), findsOneWidget);
  });

  testWidgets('register screen can navigate back to sign-in screen', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.unauthenticated,
      supabaseReady: true,
    );

    await tester.tap(find.byKey(const ValueKey('auth-go-register-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('auth-go-login-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-login-title')), findsOneWidget);
  });

  testWidgets('register screen shows otp step after successful code send', (
    tester,
  ) async {
    final controller = AppController();
    controller.debugSetAuthState(
      status: AppAuthStatus.otpSent,
      supabaseReady: true,
      pendingEmail: 'new@example.com',
    );

    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: const MaterialApp(home: EmailRegisterScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-otp-field')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth-verify-code-button')),
      findsOneWidget,
    );
    expect(find.textContaining('new@example.com'), findsOneWidget);
  });

  testWidgets('sign-in screen shows register guidance for unregistered email', (
    tester,
  ) async {
    final controller = AppController();
    controller.debugSetAuthState(
      status: AppAuthStatus.unauthenticated,
      supabaseReady: true,
      authErrorCode: 'user_not_registered',
    );

    await tester.pumpWidget(BetweenUsApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('该邮箱尚未注册，请先创建账号。'), findsOneWidget);
    expect(find.text('没有账号？去注册'), findsWidgets);
  });

  testWidgets('authenticated users without display name see the profile gate', (
    tester,
  ) async {
    await _pumpApp(tester, authStatus: AppAuthStatus.authenticated);

    expect(
      find.byKey(const ValueKey('profile-display-name-field')),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets(
    'initial authenticated sync still blocks on the profile loading screen',
    (tester) async {
      final controller = AppController();
      final reloadProfileCompleter = Completer<void>();
      final syncFuture = controller.debugSyncSessionUser(
        'user-1',
        onReloadProfile: ({bool force = false}) async {
          expect(force, isTrue);
          expect(controller.profileCheckInProgress, isTrue);
          await reloadProfileCompleter.future;
          controller.debugSeedLoadedProfile(
            userId: 'user-1',
            displayName: 'Xiaoman',
          );
        },
      );

      await tester.pumpWidget(BetweenUsApp(controller: controller));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('auth-profile-loading-screen')),
        findsOneWidget,
      );
      expect(find.byType(NavigationBar), findsNothing);

      reloadProfileCompleter.complete();
      await syncFuture;
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('auth-profile-loading-screen')),
        findsNothing,
      );
      expect(find.byType(NavigationBar), findsOneWidget);
    },
  );

  testWidgets(
    'authenticated users with placeholder display name see the profile gate',
    (tester) async {
      await _pumpApp(
        tester,
        authStatus: AppAuthStatus.authenticated,
        displayName: AppController.defaultDisplayNamePlaceholder,
      );

      expect(
        find.byKey(const ValueKey('profile-display-name-field')),
        findsOneWidget,
      );
      expect(find.byType(NavigationBar), findsNothing);
    },
  );

  testWidgets('authenticated app keeps the default zh-CN locale', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.authenticated,
      displayName: 'Xiaoman',
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.locale, const Locale('zh', 'CN'));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
  });

  testWidgets(
    'home hero shows single-user relationship state from AppController',
    (tester) async {
      await _pumpApp(
        tester,
        authStatus: AppAuthStatus.authenticated,
        displayName: '小满',
        selfProfileId: 'user-1',
        memberCount: 1,
      );

      expect(
        find.byKey(const ValueKey('home-hero-couple-names')),
        findsOneWidget,
      );
      expect(find.text('小满 · 等待另一半加入'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('home-hero-avatar-one')),
          matching: find.text('小'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('home-hero-avatar-two')),
          matching: find.text('待'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('home-hero-relationship-status')),
          matching: find.text('个人模式'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'home hero shows both names when the couple space has two members',
    (tester) async {
      await _pumpApp(
        tester,
        authStatus: AppAuthStatus.authenticated,
        language: AppLanguage.en,
        displayName: 'Xiaoman',
        selfProfileId: 'user-1',
        currentSpaceId: 'space-1',
        memberCount: 2,
        partnerDisplayName: 'Ache',
      );

      expect(find.text('Xiaoman & Ache'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('home-hero-avatar-one')),
          matching: find.text('X'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('home-hero-avatar-two')),
          matching: find.text('A'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('home-hero-relationship-status')),
          matching: find.text('Paired mode'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'same-user session refresh does not reopen the blocking profile loading screen',
    (tester) async {
      final controller = AppController();
      controller.debugSetAuthState(
        status: AppAuthStatus.authenticated,
        displayName: 'Xiaoman',
      );
      controller.debugSeedLoadedProfile(
        userId: 'user-1',
        displayName: 'Xiaoman',
      );

      await tester.pumpWidget(BetweenUsApp(controller: controller));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(
        find.byKey(const ValueKey('auth-profile-loading-screen')),
        findsNothing,
      );

      var reloadCalls = 0;
      await controller.debugSyncSessionUser(
        'user-1',
        onReloadProfile: ({bool force = false}) async {
          reloadCalls += 1;
        },
      );
      await tester.pumpAndSettle();

      expect(reloadCalls, 0);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(
        find.byKey(const ValueKey('auth-profile-loading-screen')),
        findsNothing,
      );
    },
  );

  testWidgets('sign out returns authenticated users to the email OTP gate', (
    tester,
  ) async {
    final controller = AppController();
    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      displayName: 'Xiaoman',
    );
    controller.debugSeedLoadedProfile(userId: 'user-1', displayName: 'Xiaoman');
    controller.setLanguage(AppLanguage.en);
    controller.setThemePreference(AppThemePreference.dark);
    controller.setNotificationPreviewEnabled(true);
    controller.debugSetSignOutAction(() async {});

    await tester.pumpWidget(BetweenUsApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.favorite_border),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('sign-out-tile')),
      240,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('sign-out-tile')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('sign-out-confirm-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('sign-out-confirm-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-email-field')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(controller.authStatus, AppAuthStatus.unauthenticated);
    expect(controller.displayName, isNull);
    expect(controller.language, AppLanguage.zhCn);
    expect(controller.themePreference, AppThemePreference.system);
    expect(controller.notificationPreviewEnabled, isFalse);
  });

  testWidgets('home can navigate to the calendar tab', (tester) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.authenticated,
      language: AppLanguage.en,
      displayName: 'Xiaoman',
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.calendar_month_outlined),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('calendar-selected-date-label')),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('calendar-selected-date-label')),
      findsOneWidget,
    );
  });

  testWidgets('tapping new plan from home enters plan mode', (tester) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.authenticated,
      language: AppLanguage.en,
      displayName: 'Xiaoman',
    );

    await tester.scrollUntilVisible(
      find.text('New plan'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('New plan').first);
    await tester.pumpAndSettle();

    expect(find.text('Jot down what you want to do'), findsWidgets);
    expect(find.text('Plans'), findsWidgets);
  });

  testWidgets('tapping write note from home enters note mode', (tester) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.authenticated,
      language: AppLanguage.en,
      displayName: 'Xiaoman',
    );

    await tester.scrollUntilVisible(
      find.text('Write a note'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Write a note').first);
    await tester.pumpAndSettle();

    expect(
      find.text('Leave a little something for each other'),
      findsOneWidget,
    );
    expect(find.text('Notes'), findsWidgets);
  });

  testWidgets('authenticated users can enter Us and change language/theme', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.authenticated,
      displayName: 'Xiaoman',
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.favorite_border),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    var app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('en'));
    expect(find.text('My preferences'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Dark'),
      240,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required AppAuthStatus authStatus,
  AppLanguage? language,
  bool supabaseReady = false,
  String? displayName,
  String? selfProfileId,
  String? currentSpaceId,
  int memberCount = 0,
  String? partnerDisplayName,
}) async {
  final controller = AppController();
  if (language != null) {
    controller.setLanguage(language);
  }
  controller.debugSetAuthState(
    status: authStatus,
    supabaseReady: supabaseReady,
    displayName: displayName,
    selfProfileId: selfProfileId,
    currentSpaceId: currentSpaceId,
    memberCount: memberCount,
    partnerDisplayName: partnerDisplayName,
  );

  await tester.pumpWidget(BetweenUsApp(controller: controller));
  await tester.pumpAndSettle();
}
