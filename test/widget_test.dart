import 'package:between_us/app/app_controller.dart';
import 'package:between_us/app/between_us_app.dart';
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
      displayName: '小满',
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.locale, const Locale('zh', 'CN'));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
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
      displayName: '小满',
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
}) async {
  final controller = AppController();
  if (language != null) {
    controller.setLanguage(language);
  }
  controller.debugSetAuthState(
    status: authStatus,
    supabaseReady: supabaseReady,
    displayName: displayName,
  );

  await tester.pumpWidget(BetweenUsApp(controller: controller));
  await tester.pumpAndSettle();
}
