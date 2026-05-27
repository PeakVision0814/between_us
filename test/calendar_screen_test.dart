import 'package:between_us/app/app_controller.dart';
import 'package:between_us/features/anniversaries/anniversaries_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('calendar opens in the default Chinese locale', (tester) async {
    await _pumpCalendar(tester);
    await _scrollTo(tester, find.byKey(const ValueKey('calendar-selected-date-label')));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.locale, const Locale('zh', 'CN'));
    expect(find.byKey(const ValueKey('calendar-selected-date-label')), findsOneWidget);
  });

  testWidgets('calendar shows a meaningful default selected date', (tester) async {
    await _pumpCalendar(tester);
    await _scrollTo(
      tester,
      find.byKey(const ValueKey('calendar-detail-relationship-anniversary')),
    );

    expect(
      find.byKey(const ValueKey('calendar-detail-relationship-anniversary')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('calendar-detail-empty')), findsNothing);
  });

  testWidgets('tapping another marked day updates the selected details', (
    tester,
  ) async {
    await _pumpCalendar(tester);

    await tester.tap(find.byKey(const ValueKey('calendar-day-2026-05-29')));
    await tester.pumpAndSettle();
    await _scrollTo(
      tester,
      find.byKey(const ValueKey('calendar-detail-friday-date-night')),
    );

    expect(
      find.byKey(const ValueKey('calendar-detail-friday-date-night')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('calendar-detail-relationship-anniversary')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('calendar-detail-empty')), findsNothing);
  });

  testWidgets('tapping an empty day shows the empty state instead of stale details', (
    tester,
  ) async {
    await _pumpCalendar(tester);

    await tester.tap(find.byKey(const ValueKey('calendar-day-2026-06-11')));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.byKey(const ValueKey('calendar-detail-empty')));

    expect(find.byKey(const ValueKey('calendar-detail-empty')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('calendar-detail-relationship-anniversary')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('calendar-detail-friday-date-night')),
      findsNothing,
    );
  });
}

Future<void> _pumpCalendar(WidgetTester tester) async {
  final controller = AppController();

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
        home: const Scaffold(
          body: SafeArea(
            child: CalendarScreen(),
          ),
        ),
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
