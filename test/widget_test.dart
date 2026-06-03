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

  testWidgets('register verification success returns to app root', (
    tester,
  ) async {
    final controller = _SuccessfulRegisterController();
    controller.debugSetAuthState(
      status: AppAuthStatus.otpSent,
      supabaseReady: true,
      pendingEmail: 'new@example.com',
    );

    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const EmailRegisterScreen(),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-register-title')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('auth-otp-field')),
      '123456',
    );
    await tester.tap(find.byKey(const ValueKey('auth-verify-code-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-register-title')), findsNothing);
    expect(find.text('open'), findsOneWidget);
    expect(controller.verifyCalls, 1);
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
    expect(find.byKey(const ValueKey('profile-gender-male')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-gender-female')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-birthday-button')),
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
            gender: AppController.genderFemale,
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

  testWidgets('authenticated users with unset gender see the profile gate', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.authenticated,
      displayName: 'Xiaoman',
      gender: AppController.genderUnset,
    );

    expect(
      find.byKey(const ValueKey('profile-display-name-field')),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets(
    'profile setup keeps an existing display name when gender is unset',
    (tester) async {
      await _pumpApp(
        tester,
        authStatus: AppAuthStatus.authenticated,
        displayName: 'Xiaoman',
        gender: AppController.genderUnset,
      );

      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('profile-display-name-field')),
      );
      expect(field.controller?.text, 'Xiaoman');
    },
  );

  testWidgets('profile setup requires display name and gender before submit', (
    tester,
  ) async {
    await _pumpApp(tester, authStatus: AppAuthStatus.authenticated);

    var button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('profile-save-button')),
    );
    expect(button.onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('profile-display-name-field')),
      'Xiaoman',
    );
    await tester.tap(find.byKey(const ValueKey('profile-gender-female')));
    await tester.pumpAndSettle();

    button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('profile-save-button')),
    );
    expect(button.onPressed, isNotNull);
  });

  test('appReady requires authenticated space-backed profile state', () async {
    final controller = AppController();

    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      displayName: 'Xiaoman',
    );
    expect(controller.appReady, isFalse);

    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      displayName: 'Xiaoman',
      currentSpaceId: 'space-1',
    );
    expect(controller.appReady, isTrue);

    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      displayName: 'Xiaoman',
      currentSpaceId: 'space-1',
      profileCheckInProgress: true,
    );
    expect(controller.appReady, isFalse);
  });

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
        gender: AppController.genderFemale,
      );
      controller.debugSeedLoadedProfile(
        userId: 'user-1',
        displayName: 'Xiaoman',
        gender: AppController.genderFemale,
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
      gender: AppController.genderFemale,
    );
    controller.debugSeedLoadedProfile(
      userId: 'user-1',
      displayName: 'Xiaoman',
      gender: AppController.genderFemale,
    );
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

    await tester.tap(find.byKey(const ValueKey('us-settings-icon')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-more-screen')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('sign-out-tile')),
      240,
      scrollable: find.byType(Scrollable).last,
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
      find.byKey(const ValueKey('home-quick-action-note')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-quick-action-note')));
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

    expect(find.byKey(const ValueKey('us-preferences-section')), findsNothing);
    expect(find.byKey(const ValueKey('sign-out-tile')), findsNothing);
    expect(find.text('Debug'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('us-settings-icon')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-more-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('us-preferences-section')),
      findsOneWidget,
    );

    expect(find.text('English'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    var app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('en'));
    expect(find.text('Settings & more'), findsOneWidget);

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

  testWidgets('Us screen shows invite structure in single mode', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.authenticated,
      displayName: 'Xiaoman',
      gender: AppController.genderFemale,
      memberCount: 1,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.favorite_border),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('us-hero-section')), findsOneWidget);
    expect(find.byKey(const ValueKey('us-hero-single-slot')), findsOneWidget);
    expect(find.byIcon(Icons.add), findsWidgets);

    // Tap the add avatar to navigate to invite page
    await tester.tap(find.byKey(const ValueKey('us-hero-single-slot')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('us-invite-placeholder-section')),
      findsOneWidget,
    );
  });

  testWidgets('Us screen shows paired structure and partner nickname', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.authenticated,
      language: AppLanguage.en,
      displayName: 'Xiaoman',
      gender: AppController.genderFemale,
      birthday: DateTime(1998, 6, 1),
      memberCount: 2,
      partnerDisplayName: 'Ache',
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.favorite_border),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('us-hero-section')), findsOneWidget);
    expect(find.byKey(const ValueKey('us-hero-partner-slot')), findsOneWidget);

    // Tap the partner avatar to navigate to partner profile page
    await tester.tap(find.byKey(const ValueKey('us-hero-partner-slot')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('us-partner-profile-section')),
      findsOneWidget,
    );
  });

  test(
    'profile load failure due to JWT expired signs out instead of entering profile setup',
    () async {
      final controller = AppController();
      controller.debugSetAuthState(
        status: AppAuthStatus.authenticated,
        supabaseReady: true,
      );
      controller.debugSetSignOutAction(() async {});

      await controller.debugSyncSessionUser(
        'user-1',
        onReloadProfile: ({bool force = false}) async {
          throw Exception('JWT expired');
        },
        forceBlockingProfileCheck: true,
      );

      expect(controller.authStatus, AppAuthStatus.unauthenticated);
      expect(controller.requiresProfileSetup, isFalse);
    },
  );

  test(
    'profile load failure for non-JWT reasons does not sign out',
    () async {
      final controller = AppController();
      controller.debugSetAuthState(
        status: AppAuthStatus.authenticated,
        supabaseReady: true,
      );

      await controller.debugSyncSessionUser(
        'user-1',
        onReloadProfile: ({bool force = false}) async {
          throw Exception('Network timeout');
        },
        forceBlockingProfileCheck: true,
      );

      expect(controller.authStatus, AppAuthStatus.authenticated);
    },
  );

  test(
    'requiresProfileSetup is false when profile check is in progress',
    () {
      final controller = AppController();
      controller.debugSetAuthState(
        status: AppAuthStatus.authenticated,
        supabaseReady: true,
        profileCheckInProgress: true,
      );

      expect(controller.requiresProfileSetup, isFalse);
    },
  );
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required AppAuthStatus authStatus,
  AppLanguage? language,
  bool supabaseReady = false,
  String? displayName,
  String? gender,
  DateTime? birthday,
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
    gender: gender ?? (displayName != null ? AppController.genderFemale : null),
    birthday: birthday,
    selfProfileId: selfProfileId,
    currentSpaceId: currentSpaceId,
    memberCount: memberCount,
    partnerDisplayName: partnerDisplayName,
  );

  await tester.pumpWidget(BetweenUsApp(controller: controller));
  await tester.pumpAndSettle();
}

class _SuccessfulRegisterController extends AppController {
  int verifyCalls = 0;

  @override
  Future<bool> verifyEmailOtp(String token) async {
    verifyCalls += 1;
    debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      displayName: 'Xiaoman',
      gender: AppController.genderUnset,
    );
    return true;
  }
}
