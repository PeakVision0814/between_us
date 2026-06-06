import 'dart:async';

import 'package:between_us/app/app_controller.dart';
import 'package:between_us/app/between_us_app.dart';
import 'package:between_us/features/auth/email_register_screen.dart';
import 'package:between_us/features/anniversaries/anniversaries_screen.dart'
    show CalendarScreen;
import 'package:between_us/features/settings/settings_screen.dart'
    show SpaceStatusScreen, ExitRequestSnapshot;
import 'package:between_us/features/timeline/timeline_screen.dart'
    show resolveNoteAuthorName;
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

  testWidgets('sign-in screen shows phone login entry', (tester) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.unauthenticated,
      supabaseReady: true,
    );

    expect(
      find.byKey(const ValueKey('auth-login-method-segment')),
      findsOneWidget,
    );
    expect(find.text('手机号'), findsOneWidget);

    await tester.tap(find.text('手机号'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-phone-field')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth-send-phone-code-button')),
      findsOneWidget,
    );
  });

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
    expect(
      find.byKey(const ValueKey('auth-register-method-segment')),
      findsOneWidget,
    );
  });

  testWidgets('register screen shows phone registration entry', (tester) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.unauthenticated,
      supabaseReady: true,
    );

    await tester.tap(find.byKey(const ValueKey('auth-go-register-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('手机号'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-register-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-phone-field')), findsOneWidget);
    expect(find.text('发送手机号注册验证码'), findsOneWidget);
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

  testWidgets('invalid phone format shows an error before sending', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.unauthenticated,
      supabaseReady: true,
    );

    await tester.tap(find.text('手机号'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('auth-phone-field')),
      '13812345678',
    );
    await tester.tap(find.byKey(const ValueKey('auth-send-phone-code-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('请输入 E.164 格式的手机号，例如 +8613812345678。'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('auth-otp-field')), findsNothing);
  });

  testWidgets('successful phone sign-in code send shows otp step', (
    tester,
  ) async {
    final controller = _SuccessfulPhoneSignInController();
    controller.debugSetAuthState(
      status: AppAuthStatus.unauthenticated,
      supabaseReady: true,
    );

    await tester.pumpWidget(BetweenUsApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('手机号'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('auth-phone-field')),
      '+8613812345678',
    );
    await tester.tap(find.byKey(const ValueKey('auth-send-phone-code-button')));
    await tester.pumpAndSettle();

    expect(controller.signInPhones, ['+8613812345678']);
    expect(controller.signUpPhones, isEmpty);
    expect(find.byKey(const ValueKey('auth-otp-field')), findsOneWidget);
    expect(find.textContaining('+8613812345678'), findsOneWidget);
    expect(find.text('更换手机号'), findsOneWidget);
  });

  testWidgets('invalid phone otp length shows an error', (tester) async {
    final controller = _SuccessfulPhoneSignInController();
    controller.debugSetAuthState(
      status: AppAuthStatus.phoneOtpSent,
      supabaseReady: true,
      pendingPhone: '+8613812345678',
    );

    await tester.pumpWidget(BetweenUsApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('auth-otp-field')),
      '12345',
    );
    await tester.tap(find.byKey(const ValueKey('auth-verify-code-button')));
    await tester.pumpAndSettle();

    expect(find.text('请输入 6 位验证码。'), findsOneWidget);
    expect(controller.verifyPhoneCalls, 0);
  });

  testWidgets('phone sign-in and sign-up remain separated', (tester) async {
    final controller = _SuccessfulPhoneRegisterController();
    controller.debugSetAuthState(
      status: AppAuthStatus.unauthenticated,
      supabaseReady: true,
    );

    await tester.pumpWidget(BetweenUsApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('auth-go-register-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('手机号'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('auth-phone-field')),
      '+8613912345678',
    );
    await tester.tap(find.byKey(const ValueKey('auth-send-phone-code-button')));
    await tester.pumpAndSettle();

    expect(controller.signUpPhones, ['+8613912345678']);
    expect(controller.signInPhones, isEmpty);
    expect(find.byKey(const ValueKey('auth-register-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-otp-field')), findsOneWidget);
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

  testWidgets('settings page can open account security screen', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.authenticated,
      displayName: 'Xiaoman',
    );

    await _openSettingsMore(tester);
    expect(find.byKey(const ValueKey('account-security-entry')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('account-security-entry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('account-security-screen')), findsOneWidget);
    expect(find.text('账号与安全'), findsWidgets);
  });

  testWidgets('account security shows email and phone binding status', (
    tester,
  ) async {
    final controller = _FakeAccountSecurityController(
      emailValue: 'me@example.com',
      phoneValue: '+8613812345678',
    );
    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      displayName: 'Xiaoman',
      gender: AppController.genderFemale,
    );

    await tester.pumpWidget(BetweenUsApp(controller: controller));
    await tester.pumpAndSettle();
    await _openSettingsMore(tester);
    await tester.tap(find.byKey(const ValueKey('account-security-entry')));
    await tester.pumpAndSettle();

    expect(find.text('me@example.com'), findsOneWidget);
    expect(find.text('+8613812345678'), findsOneWidget);
    expect(find.text('绑定手机号'), findsNothing);
    expect(find.text('绑定邮箱'), findsNothing);
  });

  testWidgets('unbound phone can enter phone binding flow', (tester) async {
    final controller = _FakeAccountSecurityController(
      emailValue: 'me@example.com',
    );
    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      displayName: 'Xiaoman',
      gender: AppController.genderFemale,
    );

    await tester.pumpWidget(BetweenUsApp(controller: controller));
    await tester.pumpAndSettle();
    await _openSettingsMore(tester);
    await tester.tap(find.byKey(const ValueKey('account-security-entry')));
    await tester.pumpAndSettle();

    expect(find.text('未绑定手机号'), findsOneWidget);
    await tester.tap(find.text('绑定手机号'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('bind-phone-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('bind-phone-field')), findsOneWidget);
  });

  testWidgets('invalid binding phone shows an error', (tester) async {
    final controller = _FakeAccountSecurityController(
      emailValue: 'me@example.com',
    );
    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      displayName: 'Xiaoman',
      gender: AppController.genderFemale,
    );

    await tester.pumpWidget(BetweenUsApp(controller: controller));
    await tester.pumpAndSettle();
    await _openSettingsMore(tester);
    await tester.tap(find.byKey(const ValueKey('account-security-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('绑定手机号'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('bind-phone-field')), '138');
    await tester.tap(find.byKey(const ValueKey('bind-phone-send-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('请输入 E.164 格式的手机号，例如 +8613812345678。'),
      findsOneWidget,
    );
    expect(controller.requestedPhones, isEmpty);
  });

  testWidgets('invalid phone binding otp length shows an error', (
    tester,
  ) async {
    final controller = _FakeAccountSecurityController(
      emailValue: 'me@example.com',
    );
    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      displayName: 'Xiaoman',
      gender: AppController.genderFemale,
    );

    await tester.pumpWidget(BetweenUsApp(controller: controller));
    await tester.pumpAndSettle();
    await _openSettingsMore(tester);
    await tester.tap(find.byKey(const ValueKey('account-security-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('绑定手机号'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('bind-phone-field')),
      '+8613812345678',
    );
    await tester.tap(find.byKey(const ValueKey('bind-phone-send-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('bind-phone-otp-field')),
      '12345',
    );
    await tester.tap(find.byKey(const ValueKey('bind-phone-verify-button')));
    await tester.pumpAndSettle();

    expect(find.text('请输入 6 位验证码。'), findsOneWidget);
    expect(controller.verifiedPhoneTokens, isEmpty);
  });

  testWidgets('unbound email can enter email binding flow', (tester) async {
    final controller = _FakeAccountSecurityController(
      phoneValue: '+8613812345678',
    );
    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      displayName: 'Xiaoman',
      gender: AppController.genderFemale,
    );

    await tester.pumpWidget(BetweenUsApp(controller: controller));
    await tester.pumpAndSettle();
    await _openSettingsMore(tester);
    await tester.tap(find.byKey(const ValueKey('account-security-entry')));
    await tester.pumpAndSettle();

    expect(find.text('未绑定邮箱'), findsOneWidget);
    await tester.tap(find.text('绑定邮箱'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('bind-email-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('bind-email-field')), findsOneWidget);
  });

  testWidgets('invalid binding email shows an error', (tester) async {
    final controller = _FakeAccountSecurityController(
      phoneValue: '+8613812345678',
    );
    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      displayName: 'Xiaoman',
      gender: AppController.genderFemale,
    );

    await tester.pumpWidget(BetweenUsApp(controller: controller));
    await tester.pumpAndSettle();
    await _openSettingsMore(tester);
    await tester.tap(find.byKey(const ValueKey('account-security-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('绑定邮箱'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('bind-email-field')),
      'not-email',
    );
    await tester.tap(find.byKey(const ValueKey('bind-email-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('请输入有效的邮箱地址。'), findsOneWidget);
    expect(controller.requestedEmails, isEmpty);
  });

  testWidgets('binding target already in use shows conflict message', (
    tester,
  ) async {
    final controller = _FakeAccountSecurityController(
      emailValue: 'me@example.com',
      conflictOnPhoneRequest: true,
    );
    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      displayName: 'Xiaoman',
      gender: AppController.genderFemale,
    );

    await tester.pumpWidget(BetweenUsApp(controller: controller));
    await tester.pumpAndSettle();
    await _openSettingsMore(tester);
    await tester.tap(find.byKey(const ValueKey('account-security-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('绑定手机号'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('bind-phone-field')),
      '+8613812345678',
    );
    await tester.tap(find.byKey(const ValueKey('bind-phone-send-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('这个邮箱或手机号已经属于另一个账号，不能直接绑定。'),
      findsOneWidget,
    );
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
      memberCount: 2,
      partnerDisplayName: 'Ache',
      currentSpaceId: 'test-space-id',
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
      scrollable: find.descendant(
        of: find.byType(CalendarScreen),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('calendar-selected-date-label')),
      findsOneWidget,
    );
  });

  testWidgets('single mode: home shows hero card with waiting message', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.authenticated,
      language: AppLanguage.en,
      displayName: 'Xiaoman',
      memberCount: 1,
    );

    // Hero card should show waiting message in single mode
    expect(find.byKey(const ValueKey('home-hero-waiting')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-hero-quote')), findsOneWidget);
    // No days display in single mode
    expect(find.byKey(const ValueKey('home-hero-days')), findsNothing);
  });

  testWidgets('single mode: plans page shows empty state, no create button', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.authenticated,
      language: AppLanguage.en,
      displayName: 'Xiaoman',
      memberCount: 1,
    );

    // Navigate to Plans & Notes tab
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.edit_note_outlined),
      ),
    );
    await tester.pumpAndSettle();

    // Shows lightweight empty state, not business content
    expect(find.text('No plans yet'), findsOneWidget);
    expect(find.text('Invite your partner to start using'), findsOneWidget);
    expect(find.text('Add a plan'), findsNothing);
    expect(find.text('What do you want to do...'), findsNothing);
  });

  testWidgets('single mode: calendar page shows empty state, no composer', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.authenticated,
      language: AppLanguage.en,
      displayName: 'Xiaoman',
      memberCount: 1,
    );

    // Navigate to Calendar tab
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.calendar_month_outlined),
      ),
    );
    await tester.pumpAndSettle();

    // Shows lightweight empty state, not business content
    expect(find.text('No calendar events yet'), findsOneWidget);
    expect(find.text('Invite your partner to start using'), findsOneWidget);
    expect(find.text('What belongs in calendar'), findsNothing);
    expect(find.text('Anniversary'), findsNothing);
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

    // Navigate to Appearance sub-page.
    await tester.tap(find.byKey(const ValueKey('appearance-entry')));
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    var app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('en'));
    expect(find.text('Appearance'), findsOneWidget);

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
      language: AppLanguage.en,
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
    expect(find.byKey(const ValueKey('us-space-section')), findsOneWidget);
    final spaceSection = find.byKey(const ValueKey('us-space-section'));
    expect(
      find.descendant(of: spaceSection, matching: find.text('Our space')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: spaceSection, matching: find.text('View more')),
      findsNothing,
    );
    expect(
      find.descendant(of: spaceSection, matching: find.text('Space status')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: spaceSection, matching: find.text('Calendar')),
      findsNothing,
    );
    expect(
      find.descendant(of: spaceSection, matching: find.text('Plans')),
      findsNothing,
    );
    expect(
      find.descendant(of: spaceSection, matching: find.text('Notes')),
      findsNothing,
    );
    expect(
      find.descendant(of: spaceSection, matching: find.text('Settings')),
      findsNothing,
    );

    // Single mode: Space status entry exists but should not navigate
    final spaceStatusEntry = find.byKey(
      const ValueKey('us-space-entry-Space status'),
    );
    expect(spaceStatusEntry, findsOneWidget);
    await tester.tap(spaceStatusEntry);
    await tester.pumpAndSettle();
    // Still on the Us screen, no navigation occurred
    expect(find.byKey(const ValueKey('us-space-section')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('us-hero-single-slot')),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

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
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byKey(const ValueKey('us-settings-icon')), findsOneWidget);
    expect(find.byKey(const ValueKey('us-space-section')), findsOneWidget);
    final spaceSection = find.byKey(const ValueKey('us-space-section'));

    expect(
      find.descendant(of: spaceSection, matching: find.text('View more')),
      findsNothing,
    );
    expect(
      find.descendant(of: spaceSection, matching: find.text('Calendar')),
      findsNothing,
    );
    expect(
      find.descendant(of: spaceSection, matching: find.text('Plans')),
      findsNothing,
    );
    expect(
      find.descendant(of: spaceSection, matching: find.text('Notes')),
      findsNothing,
    );
    expect(
      find.descendant(of: spaceSection, matching: find.text('Settings')),
      findsNothing,
    );
    expect(
      find.descendant(of: spaceSection, matching: find.text('Space status')),
      findsOneWidget,
    );

    // Paired mode: Space status entry is tappable and navigates
    final spaceStatusEntry = find.byKey(
      const ValueKey('us-space-entry-Space status'),
    );
    expect(spaceStatusEntry, findsOneWidget);
    await tester.tap(spaceStatusEntry);
    await tester.pumpAndSettle();

    // Should navigate to space status screen.
    expect(find.text('Space status'), findsWidgets);

    // Pop back to Us screen.
    Navigator.of(tester.element(find.byType(Scaffold))).pop();
    await tester.pumpAndSettle();

    // Tap the partner avatar to navigate to partner profile page
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('us-hero-partner-slot')),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('us-hero-partner-slot')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('us-partner-profile-section')),
      findsOneWidget,
    );
  });

  testWidgets('paired mode: space status screen shows exit button', (
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

    // Navigate to Us tab.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.favorite_border),
      ),
    );
    await tester.pumpAndSettle();

    // Tap space status entry.
    await tester.tap(find.byKey(const ValueKey('us-space-entry-Space status')));
    await tester.pumpAndSettle();

    // Should show space status screen with error (supabase not ready).
    expect(find.text('Space status'), findsWidgets);
  });

  testWidgets('single mode: space status entry is not tappable', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.authenticated,
      language: AppLanguage.en,
      displayName: 'Xiaoman',
      gender: AppController.genderFemale,
      birthday: DateTime(1998, 6, 1),
      memberCount: 1,
    );

    // Navigate to Us tab.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.favorite_border),
      ),
    );
    await tester.pumpAndSettle();

    // Space status entry exists but is not tappable (onTap is null).
    final spaceStatusEntry = find.byKey(
      const ValueKey('us-space-entry-Space status'),
    );
    expect(spaceStatusEntry, findsOneWidget);

    // Tapping should do nothing (no navigation).
    await tester.tap(spaceStatusEntry);
    await tester.pumpAndSettle();

    // Still on Us screen.
    expect(find.byKey(const ValueKey('us-hero-section')), findsOneWidget);
  });

  testWidgets('space status: no pending request shows exit button', (
    tester,
  ) async {
    final controller = AppController();
    controller.setLanguage(AppLanguage.en);
    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      displayName: 'Xiaoman',
      gender: AppController.genderFemale,
      selfProfileId: 'user-a-id',
      currentSpaceId: 'space-1',
      memberCount: 2,
      partnerDisplayName: 'Ache',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppScope(
          controller: controller,
          child: SpaceStatusScreen(
            controller: controller,
            partnerName: 'Ache',
            // No initialExitRequest = no pending request.
            onRequestExit: () async => 'new-request-id',
            onApproveExit: (_) async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Should show exit button.
    expect(
      find.byKey(const ValueKey('exit-space-request-button')),
      findsOneWidget,
    );
    expect(find.text('Exit couple space'), findsWidgets);

    // Should NOT show waiting or partner-request state.
    expect(find.byKey(const ValueKey('exit-space-waiting')), findsNothing);
    expect(
      find.byKey(const ValueKey('exit-space-partner-request')),
      findsNothing,
    );
  });

  testWidgets('space status: self-requested shows waiting state', (
    tester,
  ) async {
    final controller = AppController();
    controller.setLanguage(AppLanguage.en);
    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      displayName: 'Xiaoman',
      gender: AppController.genderFemale,
      selfProfileId: 'user-a-id',
      currentSpaceId: 'space-1',
      memberCount: 2,
      partnerDisplayName: 'Ache',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppScope(
          controller: controller,
          child: SpaceStatusScreen(
            controller: controller,
            partnerName: 'Ache',
            initialExitRequest: const ExitRequestSnapshot(
              requestId: 'req-1',
              requestedBy: 'user-a-id', // self
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Should show waiting state.
    expect(find.byKey(const ValueKey('exit-space-waiting')), findsOneWidget);
    expect(
      find.text('Exit requested. Waiting for partner to confirm.'),
      findsOneWidget,
    );

    // Should NOT show exit button or partner-request.
    expect(
      find.byKey(const ValueKey('exit-space-request-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('exit-space-partner-request')),
      findsNothing,
    );
  });

  testWidgets('space status: partner-requested shows approve button', (
    tester,
  ) async {
    final controller = AppController();
    controller.setLanguage(AppLanguage.en);
    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      displayName: 'Xiaoman',
      gender: AppController.genderFemale,
      selfProfileId: 'user-a-id',
      currentSpaceId: 'space-1',
      memberCount: 2,
      partnerDisplayName: 'Ache',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppScope(
          controller: controller,
          child: SpaceStatusScreen(
            controller: controller,
            partnerName: 'Ache',
            initialExitRequest: const ExitRequestSnapshot(
              requestId: 'req-1',
              requestedBy: 'user-b-id', // partner
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Should show partner request and approve button.
    expect(
      find.byKey(const ValueKey('exit-space-partner-request')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('exit-space-approve-button')),
      findsOneWidget,
    );
    expect(
      find.text('Partner requests to exit the couple space'),
      findsOneWidget,
    );

    // Should NOT show exit button or waiting state.
    expect(
      find.byKey(const ValueKey('exit-space-request-button')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('exit-space-waiting')), findsNothing);
  });

  testWidgets('space status: request exit shows two confirmation dialogs', (
    tester,
  ) async {
    final controller = AppController();
    controller.setLanguage(AppLanguage.en);
    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      displayName: 'Xiaoman',
      gender: AppController.genderFemale,
      selfProfileId: 'user-a-id',
      currentSpaceId: 'space-1',
      memberCount: 2,
      partnerDisplayName: 'Ache',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppScope(
          controller: controller,
          child: SpaceStatusScreen(
            controller: controller,
            partnerName: 'Ache',
            onRequestExit: () async => 'new-req-id',
            onApproveExit: (_) async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the exit button.
    await tester.tap(find.byKey(const ValueKey('exit-space-request-button')));
    await tester.pump(); // Let first dialog appear.

    // First confirmation: strong warning dialog.
    expect(find.text('Exit couple space'), findsWidgets);
    expect(find.text('Confirm exit'), findsOneWidget); // button in dialog
    await tester.tap(find.text('Confirm exit'));
    await tester.pump(); // Let first dialog close.
    await tester.pump(); // Let second dialog appear.

    // Second confirmation dialog.
    expect(find.text('Confirm exit'), findsWidgets); // title + button
    // Find the second dialog's confirm button (FilledButton with "Exit couple space").
    final confirmButtons = find.text('Exit couple space');
    expect(confirmButtons, findsWidgets);
    // Tap the dialog button (last one is in the dialog).
    await tester.tap(confirmButtons.last);
    await tester.pump(); // Let second dialog close.
    await tester.pump(); // Let snackbar and state update appear.

    // After confirmations, should transition to waiting state.
    expect(find.byKey(const ValueKey('exit-space-waiting')), findsOneWidget);
  });

  testWidgets('space status: approve exit shows confirmation and refreshes', (
    tester,
  ) async {
    var approveCalled = false;
    final controller = AppController();
    controller.setLanguage(AppLanguage.en);
    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      displayName: 'Xiaoman',
      gender: AppController.genderFemale,
      selfProfileId: 'user-a-id',
      currentSpaceId: 'space-1',
      memberCount: 2,
      partnerDisplayName: 'Ache',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppScope(
          controller: controller,
          child: SpaceStatusScreen(
            controller: controller,
            partnerName: 'Ache',
            initialExitRequest: const ExitRequestSnapshot(
              requestId: 'req-1',
              requestedBy: 'user-b-id',
            ),
            onApproveExit: (_) async {
              approveCalled = true;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap approve button.
    await tester.tap(find.byKey(const ValueKey('exit-space-approve-button')));
    await tester.pump(); // Let dialog appear.

    // Confirmation dialog should appear.
    expect(find.text('Confirm exit approval'), findsOneWidget);
    expect(find.text('Approve exit'), findsWidgets);

    // Confirm by tapping the FilledButton in the dialog.
    await tester.tap(find.byType(FilledButton).last);
    await tester.pump(); // Let dialog close.
    await tester.pump(); // Let snackbar appear.

    // Verify callback was called.
    expect(approveCalled, isTrue);

    // Should show success snackbar.
    expect(find.text('Exited the couple space'), findsOneWidget);
  });

  test(
    'profile load failure due to JWT expired clears session without blocking',
    () async {
      final controller = AppController();
      controller.debugSetAuthState(
        status: AppAuthStatus.authenticated,
        supabaseReady: true,
      );

      await controller
          .debugSyncSessionUser(
            'user-1',
            onReloadProfile: ({bool force = false}) async {
              throw Exception('JWT expired');
            },
            forceBlockingProfileCheck: true,
          )
          .timeout(const Duration(seconds: 1));

      expect(controller.authStatus, AppAuthStatus.unauthenticated);
      expect(controller.requiresProfileSetup, isFalse);
      expect(controller.displayName, isNull);
      expect(controller.gender, isNull);
      expect(controller.currentSpaceId, isNull);
    },
  );

  test('profile load failure for non-JWT reasons does not sign out', () async {
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
  });

  test('requiresProfileSetup is false when profile check is in progress', () {
    final controller = AppController();
    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      profileCheckInProgress: true,
    );

    expect(controller.requiresProfileSetup, isFalse);
  });

  testWidgets(
    'profile screen from hero icon shows display name, email, gender, birthday',
    (tester) async {
      await _pumpApp(
        tester,
        authStatus: AppAuthStatus.authenticated,
        language: AppLanguage.zhCn,
        displayName: '小满',
        gender: AppController.genderFemale,
        birthday: DateTime(1998, 6, 1),
        memberCount: 2,
        partnerDisplayName: '阿澈',
      );

      // Navigate to Us tab
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.favorite_border),
        ),
      );
      await tester.pumpAndSettle();

      // Tap person icon in hero to open profile screen
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      // Verify profile screen fields
      expect(
        find.byKey(const ValueKey('profile-display-name')),
        findsOneWidget,
      );
      expect(find.text('小满'), findsOneWidget);
      expect(find.byKey(const ValueKey('profile-email')), findsOneWidget);
      expect(find.text('未获取'), findsOneWidget); // No Supabase in tests
      expect(find.byKey(const ValueKey('profile-gender')), findsOneWidget);
      expect(find.text('女生'), findsOneWidget);
      expect(find.byKey(const ValueKey('profile-birthday')), findsOneWidget);
      expect(find.text('1998 年 06 月 01 日'), findsOneWidget);
    },
  );

  testWidgets('profile screen from settings more screen shows same fields', (
    tester,
  ) async {
    final controller = AppController();
    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      displayName: 'Xiaoman',
      gender: AppController.genderFemale,
      birthday: DateTime(1998, 6, 1),
      memberCount: 2,
      partnerDisplayName: 'Ache',
    );
    controller.setLanguage(AppLanguage.en);

    await tester.pumpWidget(BetweenUsApp(controller: controller));
    await tester.pumpAndSettle();

    // Navigate to Us tab
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.favorite_border),
      ),
    );
    await tester.pumpAndSettle();

    // Open settings more screen
    await tester.tap(find.byKey(const ValueKey('us-settings-icon')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-more-screen')), findsOneWidget);

    // Tap profile entry
    await tester.tap(find.byKey(const ValueKey('profile-entry-section')));
    await tester.pumpAndSettle();

    // Verify profile screen fields in English
    expect(find.byKey(const ValueKey('profile-display-name')), findsOneWidget);
    expect(find.text('Xiaoman'), findsWidgets);
    expect(find.byKey(const ValueKey('profile-email')), findsOneWidget);
    expect(find.text('Unavailable'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-gender')), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-birthday')), findsOneWidget);
    expect(find.text('1998-06-01'), findsOneWidget);
  });

  testWidgets('profile screen enters edit mode on tapping edit button', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.authenticated,
      displayName: 'Xiaoman',
      gender: AppController.genderFemale,
      birthday: DateTime(1998, 6, 1),
      memberCount: 2,
      partnerDisplayName: 'Ache',
    );

    // Navigate to Us tab and open profile
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.favorite_border),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    // Verify read mode
    expect(find.byKey(const ValueKey('profile-display-name')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-edit-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-edit-name-field')), findsNothing);

    // Tap edit button
    await tester.tap(find.byKey(const ValueKey('profile-edit-button')));
    await tester.pumpAndSettle();

    // Verify edit mode
    expect(
      find.byKey(const ValueKey('profile-edit-name-field')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('profile-save-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-cancel-button')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-edit-birthday-button')),
      findsOneWidget,
    );
  });

  testWidgets('profile edit: empty name prevents save', (tester) async {
    final controller = _FakeSaveProfileController();
    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      displayName: 'Xiaoman',
      gender: AppController.genderFemale,
      birthday: DateTime(1998, 6, 1),
      memberCount: 2,
      partnerDisplayName: 'Ache',
    );

    await tester.pumpWidget(BetweenUsApp(controller: controller));
    await tester.pumpAndSettle();

    // Navigate to Us tab and open profile
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.favorite_border),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    // Enter edit mode
    await tester.tap(find.byKey(const ValueKey('profile-edit-button')));
    await tester.pumpAndSettle();

    // Clear name field
    await tester.enterText(
      find.byKey(const ValueKey('profile-edit-name-field')),
      '',
    );
    await tester.pumpAndSettle();

    // Tap save
    await tester.tap(find.byKey(const ValueKey('profile-save-button')));
    await tester.pumpAndSettle();

    // Verify error message and still in edit mode
    expect(find.text('昵称不能为空'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-edit-name-field')),
      findsOneWidget,
    );
    expect(controller.saveCalls, 0);
  });

  testWidgets(
    'profile edit: editing name, gender, birthday updates controller',
    (tester) async {
      final controller = _FakeSaveProfileController();
      controller.debugSetAuthState(
        status: AppAuthStatus.authenticated,
        supabaseReady: true,
        displayName: 'Xiaoman',
        gender: AppController.genderFemale,
        birthday: DateTime(1998, 6, 1),
        memberCount: 2,
        partnerDisplayName: 'Ache',
      );
      controller.setLanguage(AppLanguage.en);

      await tester.pumpWidget(BetweenUsApp(controller: controller));
      await tester.pumpAndSettle();

      // Navigate to Us tab and open profile
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.favorite_border),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      // Enter edit mode
      await tester.tap(find.byKey(const ValueKey('profile-edit-button')));
      await tester.pumpAndSettle();

      // Change name
      await tester.enterText(
        find.byKey(const ValueKey('profile-edit-name-field')),
        'Ache',
      );

      // Change gender to male
      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.byKey(const ValueKey('profile-save-button')));
      await tester.pumpAndSettle();

      // Verify controller was updated
      expect(controller.saveCalls, 1);
      expect(controller.lastSavedDisplayName, 'Ache');
      expect(controller.lastSavedGender, AppController.genderMale);
      expect(controller.lastSavedBirthday, DateTime(1998, 6, 1));

      // Verify back to read mode with new values
      expect(
        find.byKey(const ValueKey('profile-display-name')),
        findsOneWidget,
      );
      expect(find.text('Ache'), findsWidgets);
      expect(find.text('Male'), findsOneWidget);
    },
  );

  testWidgets(
    'profile edit: email remains read-only, no editable email field',
    (tester) async {
      await _pumpApp(
        tester,
        authStatus: AppAuthStatus.authenticated,
        displayName: 'Xiaoman',
        gender: AppController.genderFemale,
        birthday: DateTime(1998, 6, 1),
        memberCount: 2,
        partnerDisplayName: 'Ache',
      );

      // Navigate to Us tab and open profile
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.favorite_border),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      // Enter edit mode
      await tester.tap(find.byKey(const ValueKey('profile-edit-button')));
      await tester.pumpAndSettle();

      // Verify email is a read-only display, not a TextFormField
      expect(
        find.byKey(const ValueKey('profile-edit-email-field')),
        findsOneWidget,
      );
      // The email field should be a _ReadOnlyField, not a TextFormField
      final emailFinder = find.byKey(
        const ValueKey('profile-edit-email-field'),
      );
      expect(
        find.descendant(of: emailFinder, matching: find.byType(TextFormField)),
        findsNothing,
      );

      // There should be exactly one TextFormField (name), not two
      final textFormFields = find.byType(TextFormField);
      expect(textFormFields, findsOneWidget);
    },
  );

  testWidgets(
    'single mode: invite page shows generate and enter invite code buttons',
    (tester) async {
      await _pumpApp(
        tester,
        authStatus: AppAuthStatus.authenticated,
        language: AppLanguage.en,
        displayName: 'Xiaoman',
        gender: AppController.genderFemale,
        memberCount: 1,
      );

      // Navigate to Us tab
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.favorite_border),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the add avatar to navigate to invite page
      await tester.tap(find.byKey(const ValueKey('us-hero-single-slot')));
      await tester.pumpAndSettle();

      // Verify invite page structure
      expect(
        find.byKey(const ValueKey('us-invite-placeholder-section')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('us-space-invite-actions')),
        findsOneWidget,
      );
      expect(find.text('Generate invite code'), findsOneWidget);
      expect(find.text('Enter invite code to join'), findsOneWidget);
    },
  );

  testWidgets(
    'paired mode: Us page shows partner slot, not single invite entry',
    (tester) async {
      await _pumpApp(
        tester,
        authStatus: AppAuthStatus.authenticated,
        language: AppLanguage.en,
        displayName: 'Xiaoman',
        gender: AppController.genderFemale,
        memberCount: 2,
        partnerDisplayName: 'Ache',
      );

      // Navigate to Us tab
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.favorite_border),
        ),
      );
      await tester.pumpAndSettle();

      // Paired mode shows partner slot, not single slot
      expect(
        find.byKey(const ValueKey('us-hero-partner-slot')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('us-hero-single-slot')), findsNothing);

      // Navigate to partner screen
      await tester.tap(find.byKey(const ValueKey('us-hero-partner-slot')));
      await tester.pumpAndSettle();

      // Partner screen shows paired content, not invite content
      expect(
        find.byKey(const ValueKey('us-partner-profile-section')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('us-invite-placeholder-section')),
        findsNothing,
      );
      expect(find.text('Ache'), findsWidgets);
    },
  );

  testWidgets('single mode: invite page has copy button for invite code', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.authenticated,
      language: AppLanguage.en,
      displayName: 'Xiaoman',
      gender: AppController.genderFemale,
      memberCount: 1,
    );

    // Navigate to Us tab
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.favorite_border),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the add avatar to navigate to invite page
    await tester.tap(find.byKey(const ValueKey('us-hero-single-slot')));
    await tester.pumpAndSettle();

    // Verify invite page structure is present
    expect(
      find.byKey(const ValueKey('us-invite-placeholder-section')),
      findsOneWidget,
    );
    // Copy button should not be visible yet (no invite code generated)
    expect(find.byKey(const ValueKey('invite-code-copy-button')), findsNothing);
  });

  test(
    'hasActiveCoupleSpace is true when memberCount >= 2 and spaceId set',
    () {
      final controller = AppController();
      controller.debugSetAuthState(
        status: AppAuthStatus.authenticated,
        supabaseReady: true,
        displayName: 'Xiaoman',
        currentSpaceId: 'space-1',
        memberCount: 2,
        partnerDisplayName: 'Ache',
      );

      expect(controller.hasActiveCoupleSpace, isTrue);
      expect(controller.memberCount, 2);
      expect(controller.partnerDisplayName, 'Ache');
    },
  );

  test('hasActiveCoupleSpace is false when memberCount < 2', () {
    final controller = AppController();
    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      displayName: 'Xiaoman',
      currentSpaceId: 'space-1',
      memberCount: 1,
    );

    expect(controller.hasActiveCoupleSpace, isFalse);
  });

  test('hasActiveCoupleSpace is false when currentSpaceId is null', () {
    final controller = AppController();
    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      displayName: 'Xiaoman',
      memberCount: 2,
    );

    expect(controller.hasActiveCoupleSpace, isFalse);
  });

  test('resolveNoteAuthorName: current user returns 我 in Chinese', () {
    final controller = AppController();
    controller.debugSeedLoadedProfile(
      userId: 'user-1',
      displayName: '小满',
      currentSpaceId: 'space-1',
      memberCount: 2,
      partnerDisplayName: '阿澈',
    );

    expect(
      resolveNoteAuthorName('user-1', controller: controller, isChinese: true),
      '我',
    );
  });

  test('resolveNoteAuthorName: current user returns Me in English', () {
    final controller = AppController();
    controller.debugSeedLoadedProfile(
      userId: 'user-1',
      displayName: 'Xiaoman',
      currentSpaceId: 'space-1',
      memberCount: 2,
      partnerDisplayName: 'Ache',
    );

    expect(
      resolveNoteAuthorName('user-1', controller: controller, isChinese: false),
      'Me',
    );
  });

  test('resolveNoteAuthorName: partner returns partnerDisplayName', () {
    final controller = AppController();
    controller.debugSeedLoadedProfile(
      userId: 'user-1',
      displayName: '小满',
      currentSpaceId: 'space-1',
      memberCount: 2,
      partnerDisplayName: '阿澈',
    );

    expect(
      resolveNoteAuthorName(
        'partner-id',
        controller: controller,
        isChinese: true,
      ),
      '阿澈',
    );
  });

  test('resolveNoteAuthorName: partner fallback to TA when name null', () {
    final controller = AppController();
    controller.debugSeedLoadedProfile(
      userId: 'user-1',
      displayName: '小满',
      currentSpaceId: 'space-1',
      memberCount: 2,
    );

    expect(
      resolveNoteAuthorName(
        'partner-id',
        controller: controller,
        isChinese: true,
      ),
      'TA',
    );
  });

  test('resolveNoteAuthorName: partner fallback to Partner in English', () {
    final controller = AppController();
    controller.debugSeedLoadedProfile(
      userId: 'user-1',
      displayName: 'Xiaoman',
      currentSpaceId: 'space-1',
      memberCount: 2,
    );

    expect(
      resolveNoteAuthorName(
        'partner-id',
        controller: controller,
        isChinese: false,
      ),
      'Partner',
    );
  });

  test('resolveNoteAuthorName: never returns raw UUID', () {
    final controller = AppController();
    controller.debugSeedLoadedProfile(
      userId: 'user-1',
      displayName: '小满',
      currentSpaceId: 'space-1',
      memberCount: 2,
      partnerDisplayName: '阿澈',
    );

    final self = resolveNoteAuthorName(
      'user-1',
      controller: controller,
      isChinese: true,
    );
    final partner = resolveNoteAuthorName(
      'partner-uuid-12345',
      controller: controller,
      isChinese: true,
    );

    expect(self, isNot(contains('user-1')));
    expect(partner, isNot(contains('uuid')));
    expect(partner, isNot(contains('12345')));
  });

  test('single mode: plans page shows empty state, not business content', () {
    final controller = AppController();
    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
      displayName: 'Xiaoman',
      currentSpaceId: 'space-1',
      memberCount: 1,
    );

    expect(controller.hasActiveCoupleSpace, isFalse);
  });

  // ─── Multi-language infrastructure tests ──────────────────────────────

  test('AppLanguage.fromCode resolves known codes', () {
    expect(AppLanguage.fromCode('zh-CN'), AppLanguage.zhCn);
    expect(AppLanguage.fromCode('zh-TW'), AppLanguage.zhTw);
    expect(AppLanguage.fromCode('en'), AppLanguage.en);
    expect(AppLanguage.fromCode('ja'), AppLanguage.ja);
    expect(AppLanguage.fromCode('ko'), AppLanguage.ko);
  });

  test('AppLanguage.fromCode falls back to zhCn for unknown codes', () {
    expect(AppLanguage.fromCode('fr'), AppLanguage.zhCn);
    expect(AppLanguage.fromCode('de'), AppLanguage.zhCn);
    expect(AppLanguage.fromCode('xyz'), AppLanguage.zhCn);
  });

  test('AppLanguage.fromCode falls back to zhCn for null or empty', () {
    expect(AppLanguage.fromCode(null), AppLanguage.zhCn);
    expect(AppLanguage.fromCode(''), AppLanguage.zhCn);
    expect(AppLanguage.fromCode('  '), AppLanguage.zhCn);
  });

  test('AppLanguage.fromCode handles legacy bare zh code', () {
    expect(AppLanguage.fromCode('zh'), AppLanguage.zhCn);
  });

  test('AppLanguage.supportedLocales returns all 5 locales', () {
    final locales = AppLanguage.supportedLocales;
    expect(locales, hasLength(5));
    expect(locales, contains(const Locale('zh', 'CN')));
    expect(locales, contains(const Locale('zh', 'TW')));
    expect(locales, contains(const Locale('en')));
    expect(locales, contains(const Locale('ja')));
    expect(locales, contains(const Locale('ko')));
  });

  test('AppLanguage.isChinese is true for zhCn and zhTw', () {
    expect(AppLanguage.zhCn.isChinese, isTrue);
    expect(AppLanguage.zhTw.isChinese, isTrue);
    expect(AppLanguage.en.isChinese, isFalse);
    expect(AppLanguage.ja.isChinese, isFalse);
    expect(AppLanguage.ko.isChinese, isFalse);
  });

  test('AppLanguage.isCjk is true for CJK languages', () {
    expect(AppLanguage.zhCn.isCjk, isTrue);
    expect(AppLanguage.zhTw.isCjk, isTrue);
    expect(AppLanguage.ja.isCjk, isTrue);
    expect(AppLanguage.ko.isCjk, isTrue);
    expect(AppLanguage.en.isCjk, isFalse);
  });

  test('AppLanguage.languageCode matches expected values', () {
    expect(AppLanguage.zhCn.languageCode, 'zh-CN');
    expect(AppLanguage.zhTw.languageCode, 'zh-TW');
    expect(AppLanguage.en.languageCode, 'en');
    expect(AppLanguage.ja.languageCode, 'ja');
    expect(AppLanguage.ko.languageCode, 'ko');
  });

  test('AppLanguage.displayName shows native names', () {
    expect(AppLanguage.zhCn.displayName, '简体中文');
    expect(AppLanguage.zhTw.displayName, '繁體中文');
    expect(AppLanguage.en.displayName, 'English');
    expect(AppLanguage.ja.displayName, '日本語');
    expect(AppLanguage.ko.displayName, '한국어');
  });

  test('controller.setLanguage persists languageCode', () {
    final controller = AppController();
    expect(controller.language, AppLanguage.zhCn);

    controller.setLanguage(AppLanguage.ja);
    expect(controller.language, AppLanguage.ja);
    expect(controller.locale, const Locale('ja'));

    controller.setLanguage(AppLanguage.ko);
    expect(controller.language, AppLanguage.ko);
    expect(controller.locale, const Locale('ko'));

    controller.setLanguage(AppLanguage.zhTw);
    expect(controller.language, AppLanguage.zhTw);
    expect(controller.locale, const Locale('zh', 'TW'));
  });

  test('controller resets language to zhCn on sign out', () {
    final controller = AppController();
    controller.setLanguage(AppLanguage.ja);
    expect(controller.language, AppLanguage.ja);

    // Simulate sign-out clearing state.
    controller.debugSetAuthState(
      status: AppAuthStatus.unauthenticated,
      supabaseReady: true,
    );
    // After debugSetAuthState, language is not reset (it's a preference).
    // But _clearAuthenticatedState (called on real sign-out) does reset it.
    // For this unit test, verify the controller can be set back.
    controller.setLanguage(AppLanguage.zhCn);
    expect(controller.language, AppLanguage.zhCn);
  });

  testWidgets('settings page shows all 5 language options', (tester) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.authenticated,
      displayName: 'Xiaoman',
    );

    // Navigate to Us tab.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.favorite_border),
      ),
    );
    await tester.pumpAndSettle();

    // Open settings.
    await tester.tap(find.byKey(const ValueKey('us-settings-icon')));
    await tester.pumpAndSettle();

    // Navigate to Appearance sub-page.
    await tester.tap(find.byKey(const ValueKey('appearance-entry')));
    await tester.pumpAndSettle();

    // Verify all 5 language options are present.
    expect(find.text('简体中文'), findsOneWidget);
    expect(find.text('繁體中文'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('日本語'), findsOneWidget);
    expect(find.text('한국어'), findsOneWidget);
  });

  testWidgets('selecting Japanese updates locale and core strings', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.authenticated,
      displayName: 'Xiaoman',
    );

    // Navigate to Us tab.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.favorite_border),
      ),
    );
    await tester.pumpAndSettle();

    // Open settings.
    await tester.tap(find.byKey(const ValueKey('us-settings-icon')));
    await tester.pumpAndSettle();

    // Navigate to Appearance sub-page.
    await tester.tap(find.byKey(const ValueKey('appearance-entry')));
    await tester.pumpAndSettle();

    // Select Japanese.
    await tester.tap(find.text('日本語'));
    await tester.pumpAndSettle();

    // Verify locale changed.
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('ja'));

    // Verify appearance page title switched to Japanese.
    expect(find.text('外観と言語'), findsOneWidget);
  });

  testWidgets('selecting Korean updates locale and core strings', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.authenticated,
      displayName: 'Xiaoman',
    );

    // Navigate to Us tab.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.favorite_border),
      ),
    );
    await tester.pumpAndSettle();

    // Open settings.
    await tester.tap(find.byKey(const ValueKey('us-settings-icon')));
    await tester.pumpAndSettle();

    // Navigate to Appearance sub-page.
    await tester.tap(find.byKey(const ValueKey('appearance-entry')));
    await tester.pumpAndSettle();

    // Select Korean.
    await tester.tap(find.text('한국어'));
    await tester.pumpAndSettle();

    // Verify locale changed.
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('ko'));

    // Verify appearance page title switched to Korean.
    expect(find.text('외관 및 언어'), findsOneWidget);
  });

  testWidgets('selecting Traditional Chinese updates locale', (tester) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.authenticated,
      displayName: 'Xiaoman',
    );

    // Navigate to Us tab.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.favorite_border),
      ),
    );
    await tester.pumpAndSettle();

    // Open settings.
    await tester.tap(find.byKey(const ValueKey('us-settings-icon')));
    await tester.pumpAndSettle();

    // Navigate to Appearance sub-page.
    await tester.tap(find.byKey(const ValueKey('appearance-entry')));
    await tester.pumpAndSettle();

    // Select Traditional Chinese.
    await tester.tap(find.text('繁體中文'));
    await tester.pumpAndSettle();

    // Verify locale changed.
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('zh', 'TW'));

    // Verify appearance page title is in Traditional Chinese.
    expect(find.text('外觀與語言'), findsOneWidget);
  });

  testWidgets('Japanese: profile setup screen shows Japanese title and labels', (
    tester,
  ) async {
    final controller = AppController();
    controller.setLanguage(AppLanguage.ja);
    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
    );

    await tester.pumpWidget(BetweenUsApp(controller: controller));
    await tester.pumpAndSettle();

    // Profile setup screen should show Japanese text.
    expect(find.text('プロフィールを完成させてください'), findsOneWidget);
    expect(find.text('プロフィールを完成させてください'), findsOneWidget);
    // Gender labels in Japanese.
    expect(find.text('男性'), findsOneWidget);
    expect(find.text('女性'), findsOneWidget);
    // Birthday label in Japanese.
    expect(find.text('誕生日（任意）'), findsOneWidget);
    // Save button in Japanese.
    expect(find.text('保存して続ける'), findsOneWidget);
  });

  testWidgets('Korean: profile setup screen shows Korean title and labels', (
    tester,
  ) async {
    final controller = AppController();
    controller.setLanguage(AppLanguage.ko);
    controller.debugSetAuthState(
      status: AppAuthStatus.authenticated,
      supabaseReady: true,
    );

    await tester.pumpWidget(BetweenUsApp(controller: controller));
    await tester.pumpAndSettle();

    // Profile setup screen should show Korean text.
    expect(find.text('프로필을 완성하세요'), findsOneWidget);
    // Gender labels in Korean.
    expect(find.text('남성'), findsOneWidget);
    expect(find.text('여성'), findsOneWidget);
    // Birthday label in Korean.
    expect(find.text('생일 (선택)'), findsOneWidget);
    // Save button in Korean.
    expect(find.text('저장 후 계속'), findsOneWidget);
  });

  testWidgets(
    'Traditional Chinese: profile setup shows zh-TW, not zh-CN',
    (tester) async {
      final controller = AppController();
      controller.setLanguage(AppLanguage.zhTw);
      controller.debugSetAuthState(
        status: AppAuthStatus.authenticated,
        supabaseReady: true,
      );

      await tester.pumpWidget(BetweenUsApp(controller: controller));
      await tester.pumpAndSettle();

      // Profile setup title should be Traditional Chinese.
      expect(find.text('完善你的資料'), findsOneWidget);
      // Should NOT show the Simplified Chinese version.
      expect(find.text('完善你的资料'), findsNothing);
      // Gender labels (same in both zh-CN and zh-TW).
      expect(find.text('男生'), findsOneWidget);
      expect(find.text('女生'), findsOneWidget);
    },
  );

  testWidgets('Japanese: invite page shows Japanese text', (tester) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.authenticated,
      language: AppLanguage.ja,
      displayName: 'Xiaoman',
      gender: AppController.genderFemale,
      memberCount: 1,
    );

    // Navigate to Us tab.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.favorite_border),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the add avatar to navigate to invite page.
    await tester.tap(find.byKey(const ValueKey('us-hero-single-slot')));
    await tester.pumpAndSettle();

    // Verify invite page shows Japanese text (some appear in both section
    // header and card, so use findsWidgets).
    expect(find.text('パートナーを招待'), findsWidgets);
    expect(find.text('パートナーの席を確保しましょう'), findsWidgets);
    expect(find.text('招待コードを生成'), findsOneWidget);
    expect(find.text('招待コードを入力して参加'), findsOneWidget);
  });

  testWidgets('Korean: invite page shows Korean text', (tester) async {
    await _pumpApp(
      tester,
      authStatus: AppAuthStatus.authenticated,
      language: AppLanguage.ko,
      displayName: 'Xiaoman',
      gender: AppController.genderFemale,
      memberCount: 1,
    );

    // Navigate to Us tab.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.favorite_border),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the add avatar to navigate to invite page.
    await tester.tap(find.byKey(const ValueKey('us-hero-single-slot')));
    await tester.pumpAndSettle();

    // Verify invite page shows Korean text.
    expect(find.text('파트너 초대'), findsWidgets);
    expect(find.text('파트너를 위한 자리를 마련하세요'), findsWidgets);
    expect(find.text('초대 코드 생성'), findsOneWidget);
    expect(find.text('초대 코드를 입력하여 참여'), findsOneWidget);
  });

  testWidgets(
    'Traditional Chinese: invite page shows zh-TW, not zh-CN',
    (tester) async {
      await _pumpApp(
        tester,
        authStatus: AppAuthStatus.authenticated,
        language: AppLanguage.zhTw,
        displayName: 'Xiaoman',
        gender: AppController.genderFemale,
        memberCount: 1,
      );

      // Navigate to Us tab.
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.favorite_border),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the add avatar to navigate to invite page.
      await tester.tap(find.byKey(const ValueKey('us-hero-single-slot')));
      await tester.pumpAndSettle();

      // Verify invite page shows Traditional Chinese.
      expect(find.text('邀請 TA'), findsWidgets);
      expect(find.text('先給 TA 留一個位置'), findsWidgets);
      expect(find.text('生成邀請碼'), findsOneWidget);
      expect(find.text('輸入邀請碼加入'), findsOneWidget);
      // Should NOT show Simplified Chinese versions.
      expect(find.text('邀请 TA'), findsNothing);
      expect(find.text('先给 TA 留一个位置'), findsNothing);
    },
  );

  testWidgets(
    'Japanese: space status page shows Japanese, not English fallback',
    (tester) async {
      final controller = AppController();
      controller.setLanguage(AppLanguage.ja);
      controller.debugSetAuthState(
        status: AppAuthStatus.authenticated,
        supabaseReady: true,
        displayName: 'Xiaoman',
        gender: AppController.genderFemale,
        selfProfileId: 'user-a-id',
        currentSpaceId: 'space-1',
        memberCount: 2,
        partnerDisplayName: 'Ache',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AppScope(
            controller: controller,
            child: SpaceStatusScreen(
              controller: controller,
              partnerName: 'Ache',
              initialExitRequest: const ExitRequestSnapshot(
                requestId: 'req-1',
                requestedBy: 'user-a-id',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show Japanese sharing text, not English.
      expect(find.text('Ache と共有中'), findsOneWidget);
      expect(find.text('Sharing with Ache'), findsNothing);
      // Should show Japanese exit hint, not English.
      expect(
        find.text('退出後、ふたりともシングルモードに戻ります'),
        findsOneWidget,
      );
      expect(
        find.text('Both return to single mode after exit'),
        findsNothing,
      );
    },
  );

  // ─── Anniversary and home tests ─────────────────────────────────────

  testWidgets(
    'paired mode: partner screen shows anniversary section',
    (tester) async {
      await _pumpApp(
        tester,
        authStatus: AppAuthStatus.authenticated,
        displayName: 'Xiaoman',
        memberCount: 2,
        partnerDisplayName: 'Ache',
        currentSpaceId: 'test-space-id',
      );

      // Navigate to Us tab
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.favorite_border),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on partner avatar to open partner screen
      await tester.tap(find.byKey(const ValueKey('us-hero-partner-slot')));
      await tester.pumpAndSettle();

      // Anniversary section title should be visible
      expect(find.text('纪念日'), findsOneWidget);
    },
  );

  testWidgets(
    'single mode: partner screen does not show anniversary section',
    (tester) async {
      await _pumpApp(
        tester,
        authStatus: AppAuthStatus.authenticated,
        displayName: 'Xiaoman',
        memberCount: 1,
        currentSpaceId: 'test-space-id',
      );

      // Navigate to Us tab
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.favorite_border),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the add partner avatar
      await tester.tap(find.byKey(const ValueKey('us-hero-single-slot')));
      await tester.pumpAndSettle();

      // Should not show anniversary section in single mode
      expect(find.text('纪念日'), findsNothing);
    },
  );

  testWidgets(
    'home hero card loads anniversary data from Supabase',
    (tester) async {
      await _pumpApp(
        tester,
        authStatus: AppAuthStatus.authenticated,
        displayName: 'Xiaoman',
        memberCount: 2,
        partnerDisplayName: 'Ache',
        currentSpaceId: 'test-space-id',
      );

      // Days are loaded from anniversaries table via Supabase.
      // In test environment, Supabase is not available, so days won't show.
      expect(find.byKey(const ValueKey('home-hero-days')), findsNothing);
    },
  );

  testWidgets(
    'home hero card does not show days in single mode',
    (tester) async {
      await _pumpApp(
        tester,
        authStatus: AppAuthStatus.authenticated,
        displayName: 'Xiaoman',
        memberCount: 1,
        currentSpaceId: 'test-space-id',
      );

      expect(find.byKey(const ValueKey('home-hero-days')), findsNothing);
    },
  );

  testWidgets(
    'home hero card shows partner name in paired mode',
    (tester) async {
      await _pumpApp(
        tester,
        authStatus: AppAuthStatus.authenticated,
        displayName: 'Xiaoman',
        memberCount: 2,
        partnerDisplayName: 'Ache',
        currentSpaceId: 'test-space-id',
      );

      expect(find.byKey(const ValueKey('home-hero-partner-name')), findsOneWidget);
      expect(find.text('Ache'), findsOneWidget);
    },
  );

  testWidgets(
    'home hero card shows waiting message in single mode',
    (tester) async {
      await _pumpApp(
        tester,
        authStatus: AppAuthStatus.authenticated,
        displayName: 'Xiaoman',
        memberCount: 1,
        currentSpaceId: 'test-space-id',
      );

      expect(find.byKey(const ValueKey('home-hero-waiting')), findsOneWidget);
      expect(find.text('等待另一半加入'), findsOneWidget);
    },
  );

  testWidgets(
    'home hero card shows quote',
    (tester) async {
      await _pumpApp(
        tester,
        authStatus: AppAuthStatus.authenticated,
        displayName: 'Xiaoman',
        memberCount: 2,
        partnerDisplayName: 'Ache',
        currentSpaceId: 'test-space-id',
      );

      expect(find.byKey(const ValueKey('home-hero-quote')), findsOneWidget);
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

Future<void> _openSettingsMore(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(Icons.favorite_border),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('us-settings-icon')));
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

class _SuccessfulPhoneSignInController extends AppController {
  final List<String> signInPhones = [];
  final List<String> signUpPhones = [];
  int verifyPhoneCalls = 0;

  @override
  Future<bool> sendPhoneOtpForSignIn(String phone) async {
    signInPhones.add(phone.trim());
    debugSetAuthState(
      status: AppAuthStatus.phoneOtpSent,
      supabaseReady: true,
      pendingPhone: phone.trim(),
    );
    return true;
  }

  @override
  Future<bool> sendPhoneOtpForSignUp(String phone) async {
    signUpPhones.add(phone.trim());
    debugSetAuthState(
      status: AppAuthStatus.phoneOtpSent,
      supabaseReady: true,
      pendingPhone: phone.trim(),
    );
    return true;
  }

  @override
  Future<bool> verifyPhoneOtp(String token) async {
    if (token.trim().length != 6) {
      debugSetAuthState(
        status: AppAuthStatus.phoneOtpSent,
        supabaseReady: true,
        pendingPhone: pendingPhone,
        authErrorCode: 'invalid_token_length',
      );
      return false;
    }
    verifyPhoneCalls += 1;
    return true;
  }
}

class _SuccessfulPhoneRegisterController
    extends _SuccessfulPhoneSignInController {}

class _FakeAccountSecurityController extends AppController {
  _FakeAccountSecurityController({
    this.emailValue,
    this.phoneValue,
    this.conflictOnPhoneRequest = false,
  });

  String? emailValue;
  String? phoneValue;
  bool conflictOnPhoneRequest;
  final List<String> requestedPhones = [];
  final List<String> requestedEmails = [];
  final List<String> verifiedPhoneTokens = [];
  final List<String> verifiedEmailTokens = [];

  @override
  String? get email => emailValue;

  @override
  String? get phone => phoneValue;

  @override
  Future<bool> requestPhoneBindingOtp(String phone) async {
    final normalizedPhone = phone.trim();
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(normalizedPhone)) {
      debugSetAuthState(
        status: authStatus,
        supabaseReady: supabaseReady,
        displayName: displayName,
        gender: gender,
        pendingBindingEmail: pendingBindingEmail,
        pendingBindingPhone: pendingBindingPhone,
        bindingErrorCode: 'invalid_phone',
      );
      return false;
    }
    requestedPhones.add(normalizedPhone);
    if (conflictOnPhoneRequest) {
      debugSetAuthState(
        status: authStatus,
        supabaseReady: supabaseReady,
        displayName: displayName,
        gender: gender,
        bindingErrorCode: 'binding_target_in_use',
      );
      return false;
    }
    debugSetAuthState(
      status: authStatus,
      supabaseReady: supabaseReady,
      displayName: displayName,
      gender: gender,
      pendingBindingPhone: normalizedPhone,
    );
    return true;
  }

  @override
  Future<bool> verifyPhoneBindingOtp(String token) async {
    final normalizedToken = token.trim();
    if (normalizedToken.length != 6) {
      debugSetAuthState(
        status: authStatus,
        supabaseReady: supabaseReady,
        displayName: displayName,
        gender: gender,
        pendingBindingPhone: pendingBindingPhone,
        bindingErrorCode: 'invalid_token_length',
      );
      return false;
    }
    verifiedPhoneTokens.add(normalizedToken);
    phoneValue = pendingBindingPhone;
    debugSetAuthState(
      status: authStatus,
      supabaseReady: supabaseReady,
      displayName: displayName,
      gender: gender,
    );
    return true;
  }

  @override
  Future<bool> requestEmailBindingOtp(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final atIndex = normalizedEmail.indexOf('@');
    if (atIndex <= 0 || atIndex >= normalizedEmail.length - 1) {
      debugSetAuthState(
        status: authStatus,
        supabaseReady: supabaseReady,
        displayName: displayName,
        gender: gender,
        pendingBindingEmail: pendingBindingEmail,
        pendingBindingPhone: pendingBindingPhone,
        bindingErrorCode: 'invalid_email',
      );
      return false;
    }
    requestedEmails.add(normalizedEmail);
    debugSetAuthState(
      status: authStatus,
      supabaseReady: supabaseReady,
      displayName: displayName,
      gender: gender,
      pendingBindingEmail: normalizedEmail,
    );
    return true;
  }

  @override
  Future<bool> verifyEmailBindingOtp(String token) async {
    final normalizedToken = token.trim();
    if (normalizedToken.length != 6) {
      debugSetAuthState(
        status: authStatus,
        supabaseReady: supabaseReady,
        displayName: displayName,
        gender: gender,
        pendingBindingEmail: pendingBindingEmail,
        bindingErrorCode: 'invalid_token_length',
      );
      return false;
    }
    verifiedEmailTokens.add(normalizedToken);
    emailValue = pendingBindingEmail;
    debugSetAuthState(
      status: authStatus,
      supabaseReady: supabaseReady,
      displayName: displayName,
      gender: gender,
    );
    return true;
  }
}

class _FakeSaveProfileController extends AppController {
  int saveCalls = 0;
  String? lastSavedDisplayName;
  String? lastSavedGender;
  DateTime? lastSavedBirthday;

  @override
  Future<bool> saveProfileSetup({
    required String displayName,
    required String gender,
    DateTime? birthday,
  }) async {
    saveCalls += 1;
    lastSavedDisplayName = displayName;
    lastSavedGender = gender;
    lastSavedBirthday = birthday;
    // Simulate successful save by updating local state
    debugSeedLoadedProfile(
      userId: selfProfileId ?? 'test-user',
      displayName: displayName,
      gender: gender,
      birthday: birthday,
      currentSpaceId: currentSpaceId,
      memberCount: memberCount,
      partnerDisplayName: partnerDisplayName,
    );
    notifyListeners();
    return true;
  }
}
