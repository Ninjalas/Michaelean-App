// Animations, step 3: rows fade and fold away, and new rows fade in.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/widgets/animated_rows.dart';

Widget rows(List<String> names) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AnimatedRows(
            separator: const Divider(height: 1),
            children: [
              for (final n in names) SizedBox(key: ValueKey(n), height: 50, child: Text(n)),
            ],
          ),
        ),
      ),
    );

/// How tall the list is right now.
double height(WidgetTester tester) => tester.getSize(find.byType(AnimatedRows)).height;

void main() {
  testWidgets('a removed row fades and folds away', (tester) async {
    await tester.pumpWidget(rows(['A', 'B', 'C']));
    final full = height(tester);
    await tester.pumpWidget(rows(['A', 'C']));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('B'), findsOneWidget); // still folding away
    expect(height(tester), allOf(lessThan(full), greaterThan(full - 51)));
    await tester.pumpAndSettle();
    expect(find.text('B'), findsNothing);
    expect(height(tester), closeTo(full - 51, 0.1)); // one row and its divider
  });

  testWidgets('a new row fades and unfolds in, in its place', (tester) async {
    await tester.pumpWidget(rows(['A', 'C']));
    await tester.pumpWidget(rows(['A', 'B', 'C']));
    await tester.pump(const Duration(milliseconds: 120));
    final b = tester.widget<FadeTransition>(
        find.ancestor(of: find.text('B'), matching: find.byType(FadeTransition)).first);
    expect(b.opacity.value, allOf(greaterThan(0), lessThan(1)));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('B')).dy,
        lessThan(tester.getTopLeft(find.text('C')).dy)); // between A and C
  });

  testWidgets('nothing animates on the first build', (tester) async {
    await tester.pumpWidget(rows(['A', 'B']));
    expect(height(tester), closeTo(101, 0.1)); // full height at once
  });

  testWidgets('a row that comes back while leaving stays', (tester) async {
    await tester.pumpWidget(rows(['A', 'B']));
    await tester.pumpWidget(rows(['A']));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpWidget(rows(['A', 'B']));
    await tester.pumpAndSettle();
    expect(find.text('B'), findsOneWidget);
    expect(height(tester), closeTo(101, 0.1));
  });

  testWidgets('with reduce motion, rows change at once', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(rows(['A', 'B', 'C']));
    await tester.pumpWidget(rows(['A', 'C']));
    await tester.pump();
    expect(find.text('B'), findsNothing);
    await tester.pumpWidget(rows(['A', 'C', 'D']));
    await tester.pump();
    expect(height(tester), closeTo(152, 0.1)); // D is fully in
  });
}
