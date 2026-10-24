// Animations, step 4: small state changes. Buttons crossfade (Connect →
// Pending), the bell's red dot shrinks away. Instant with "reduce motion".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/widgets/fade_switch.dart';
import 'package:michaelean_app/widgets/round_icon_button.dart';

Widget fade(String state) => MaterialApp(
      home: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StateFade(
              state: state,
              child: OutlinedButton(onPressed: () {}, child: Text(state)),
            ),
          ],
        ),
      ),
    );

Widget bell(bool dot) => MaterialApp(
      home: Scaffold(
        body: RoundIconButton(
            icon: Icons.notifications_none, tooltip: 'Bell', onPressed: () {}, showDot: dot),
      ),
    );

// The dot's drawn scale right now (AnimatedScale eases a ScaleTransition).
double dotScale(WidgetTester tester) => tester
    .widget<ScaleTransition>(
        find.descendant(of: find.byType(AnimatedScale), matching: find.byType(ScaleTransition)))
    .scale
    .value;

void main() {
  testWidgets('a button crossfades to its new state, keeping its width', (tester) async {
    await tester.pumpWidget(fade('Connect'));
    final width = tester.getSize(find.byType(OutlinedButton)).width;
    await tester.pumpWidget(fade('Pending'));
    await tester.pump(const Duration(milliseconds: 100));
    // Midway, both are there, each still full width.
    expect(find.text('Connect'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    for (final b in tester.widgetList(find.byType(OutlinedButton))) {
      expect(tester.getSize(find.byWidget(b)).width, width);
    }
    await tester.pumpAndSettle();
    expect(find.text('Connect'), findsNothing);
    expect(find.text('Pending'), findsOneWidget);
  });

  testWidgets('with reduce motion, the button changes at once', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(fade('Connect'));
    await tester.pumpWidget(fade('Pending'));
    await tester.pump();
    expect(find.text('Connect'), findsNothing);
  });

  testWidgets("the bell's dot shrinks away and grows back", (tester) async {
    await tester.pumpWidget(bell(true));
    expect(dotScale(tester), 1);
    await tester.pumpWidget(bell(false));
    await tester.pump(const Duration(milliseconds: 100));
    expect(dotScale(tester), inExclusiveRange(0, 1)); // midway, shrinking
    await tester.pumpAndSettle();
    expect(dotScale(tester), 0);
    await tester.pumpWidget(bell(true));
    await tester.pumpAndSettle();
    expect(dotScale(tester), 1);
  });
}
