import 'package:between_us/app/app_controller.dart';
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

  testWidgets('calendar shows empty state when no events', (tester) async {
    await _pumpCalendar(tester);

    await _scrollTo(tester, find.text('还没有日历事件'));

    expect(find.text('还没有日历事件'), findsOneWidget);
  });

  testWidgets('calendar has month view and composer', (tester) async {
    await _pumpCalendar(tester);

    await _scrollTo(tester, find.byKey(const ValueKey('calendar-selected-date-label')));

    expect(find.byKey(const ValueKey('calendar-selected-date-label')), findsOneWidget);
    expect(find.text('纪念日'), findsWidgets);
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
