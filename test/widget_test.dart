import 'package:between_us/app/between_us_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'app defaults to simplified Chinese and shows four primary tabs',
    (tester) async {
      await tester.pumpWidget(const BetweenUsApp());

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(app.locale, const Locale('zh', 'CN'));
      expect(find.text('首页'), findsWidgets);
      expect(find.text('日历'), findsOneWidget);
      expect(find.text('计划笔记'), findsOneWidget);
      expect(find.text('我们'), findsOneWidget);
    },
  );

  testWidgets('home shows the main status modules', (tester) async {
    await tester.pumpWidget(const BetweenUsApp());

    expect(find.text('小满 和 阿澈'), findsOneWidget);
    expect(find.text('关系纪念日'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('最近一个计划提醒'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    expect(find.text('最近一个计划提醒'), findsOneWidget);
    expect(find.text('把六月短途出门定下来'), findsOneWidget);
    expect(find.text('去日历'), findsOneWidget);
  });

  testWidgets(
    'tapping "新建计划" from home enters plans/notes page in plan mode',
    (tester) async {
      await tester.pumpWidget(const BetweenUsApp());

      await tester.scrollUntilVisible(
        find.text('新建计划'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('新建计划'));
      await tester.pumpAndSettle();

      expect(find.text('想做的事，先记在这里'), findsOneWidget);
      expect(find.text('计划'), findsWidgets);
    },
  );

  testWidgets(
    'tapping "写随记" from home enters plans/notes page in note mode',
    (tester) async {
      await tester.pumpWidget(const BetweenUsApp());

      await tester.scrollUntilVisible(
        find.text('写随记'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('写随记').first);
      await tester.pumpAndSettle();

      expect(find.text('随手留一点，给彼此看看'), findsOneWidget);
      expect(find.text('随记'), findsWidgets);
    },
  );

  testWidgets('can enter Us page and change theme and language', (
    tester,
  ) async {
    await tester.pumpWidget(const BetweenUsApp());

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.favorite_border),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('我的偏好'), findsOneWidget);
    expect(find.text('我们的空间'), findsWidgets);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    var app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('en'));
    expect(find.text('Us'), findsWidgets);
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
