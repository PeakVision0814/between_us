import 'package:between_us/app/between_us_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app defaults to simplified Chinese', (tester) async {
    await tester.pumpWidget(const BetweenUsApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.locale, const Locale('zh', 'CN'));
    expect(find.text('首页'), findsWidgets);
    expect(find.text('片刻'), findsWidgets);
    expect(find.text('日期'), findsWidgets);
    expect(find.text('留一句话'), findsWidgets);
  });

  testWidgets('bottom navigation shows moments and dates in Chinese', (
    tester,
  ) async {
    await tester.pumpWidget(const BetweenUsApp());

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.auto_awesome_outlined),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('最近的片刻'), findsOneWidget);
    expect(find.text('到家啦，楼下买到了你喜欢的豆花。'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.event_note_outlined),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('已经记下的日期'), findsOneWidget);
    expect(find.text('关系纪念日'), findsWidgets);
  });

  testWidgets('settings can switch language and theme locally', (tester) async {
    await tester.pumpWidget(const BetweenUsApp());

    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();

    expect(find.text('语言'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    var app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('en'));
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Theme mode'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);

    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();

    app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
  });
}
