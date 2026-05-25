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
    expect(find.text('Wishlist'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('bottom navigation switches sections', (tester) async {
    await tester.pumpWidget(const BetweenUsApp());

    await tester.tap(find.byIcon(Icons.timeline_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Movie night'), findsOneWidget);
  });
}
