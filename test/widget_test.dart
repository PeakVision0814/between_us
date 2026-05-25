import 'package:between_us/app/between_us_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app shell shows the main sections', (tester) async {
    await tester.pumpWidget(const BetweenUsApp());

    expect(find.text('Between Us'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('Dates'), findsOneWidget);
    expect(find.text('Write today\'s note'), findsWidgets);
    expect(find.text('Review dates'), findsOneWidget);
  });

  testWidgets('bottom navigation switches sections', (tester) async {
    await tester.pumpWidget(const BetweenUsApp());

    await tester.tap(find.byIcon(Icons.timeline_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Recent notes'), findsOneWidget);
    expect(find.text('Mon, May 25 | Movie night'), findsOneWidget);
  });

  testWidgets('home CTA opens the timeline tab', (tester) async {
    await tester.pumpWidget(const BetweenUsApp());

    await tester.tap(find.text('Write today\'s note').first);
    await tester.pumpAndSettle();

    expect(find.text('Today\'s thread'), findsOneWidget);
  });
}
