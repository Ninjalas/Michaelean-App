// Home's stats count up from 0 the first time they show, not on every
// reload. Instant with the phone's "reduce motion" setting.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/widgets/stats_row.dart';

Widget stats(String percent) => MaterialApp(
      home: Scaffold(
        body: StatsRow(items: [
          StatItem(percent, 'Class attendance', onTap: () {}),
          StatItem('3/7', 'Cleared', onTap: () {}),
        ]),
      ),
    );

/// The number shown in the first stat right now.
int shownPercent(WidgetTester tester) {
  final t = tester.widget<Text>(find.textContaining('%'));
  return int.parse(t.data!.replaceAll('%', ''));
}

void main() {
  testWidgets('the first time, numbers count up from 0', (tester) async {
    await tester.pumpWidget(stats('94%'));
    expect(shownPercent(tester), 0);
    expect(find.text('0/7'), findsOneWidget); // only the first number counts
    await tester.pump(const Duration(milliseconds: 100));
    expect(shownPercent(tester), inExclusiveRange(0, 94)); // on its way up
    await tester.pumpAndSettle();
    expect(find.text('94%'), findsOneWidget);
    expect(find.text('3/7'), findsOneWidget);
  });

  testWidgets("a reload with the same numbers doesn't replay it; a new number eases in",
      (tester) async {
    await tester.pumpWidget(stats('94%'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(stats('94%'));
    expect(find.text('94%'), findsOneWidget); // no count from 0
    await tester.pumpWidget(stats('60%'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(shownPercent(tester), inExclusiveRange(60, 94)); // from the old number, not 0
    await tester.pumpAndSettle();
    expect(find.text('60%'), findsOneWidget);
  });

  testWidgets('with reduce motion, the numbers show at once', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(stats('94%'));
    await tester.pump();
    expect(find.text('94%'), findsOneWidget);
    expect(find.text('3/7'), findsOneWidget);
  });
}
