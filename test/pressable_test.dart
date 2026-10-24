// Press feedback: cards and rows shrink slightly while pressed, then spring
// back. Scrolling, disabled rows, and reduce motion don't shrink them.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/widgets/pressable.dart';

Widget list({VoidCallback? onTap = _noop}) => MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            for (var i = 0; i < 30; i++)
              Pressable(
                key: ValueKey(i),
                onTap: onTap,
                child: SizedBox(height: 60, child: Text('Row $i')),
              ),
          ],
        ),
      ),
    );

void _noop() {}

double scale(WidgetTester tester, int row) => tester
    .widget<AnimatedScale>(
        find.descendant(of: find.byKey(ValueKey(row)), matching: find.byType(AnimatedScale)))
    .scale;

void main() {
  testWidgets('a row shrinks while pressed and springs back on release', (tester) async {
    var taps = 0;
    await tester.pumpWidget(list(onTap: () => taps++));
    final press = await tester.startGesture(tester.getCenter(find.text('Row 1')));
    await tester.pump(const Duration(milliseconds: 150)); // past the tap delay in a list
    expect(scale(tester, 1), Pressable.pressedScale);
    expect(scale(tester, 2), 1); // only the pressed row
    await press.up();
    await tester.pumpAndSettle();
    expect(scale(tester, 1), 1);
    expect(taps, 1); // still a normal tap
  });

  testWidgets('scrolling the list does not shrink the row under the finger', (tester) async {
    await tester.pumpWidget(list());
    final drag = await tester.startGesture(tester.getCenter(find.text('Row 1')));
    await drag.moveBy(const Offset(0, -40)); // a scroll, right away
    await tester.pump(const Duration(milliseconds: 150));
    expect(scale(tester, 1), 1);
    await drag.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a disabled row does not react', (tester) async {
    await tester.pumpWidget(list(onTap: null));
    final press = await tester.startGesture(tester.getCenter(find.text('Row 1')));
    await tester.pump(const Duration(milliseconds: 150));
    expect(scale(tester, 1), 1);
    await press.up();
  });

  testWidgets('with reduce motion, a pressed row keeps its size', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(list());
    final press = await tester.startGesture(tester.getCenter(find.text('Row 1')));
    await tester.pump(const Duration(milliseconds: 150));
    expect(scale(tester, 1), 1);
    await press.up();
    await tester.pumpAndSettle();
  });
}
