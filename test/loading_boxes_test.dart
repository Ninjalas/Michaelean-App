// The grey loading boxes shimmer while a page loads; with the phone's
// "reduce motion" setting they stay still.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/widgets/loading_boxes.dart';

Widget boxes() => const MaterialApp(home: Scaffold(body: LoadingBoxes(heights: [64, 120])));

void main() {
  testWidgets('the boxes shimmer, and stop once the page has loaded', (tester) async {
    await tester.pumpWidget(boxes());
    expect(find.byType(ShaderMask), findsOneWidget);
    // The light keeps sweeping: frames keep coming while loading.
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.binding.hasScheduledFrame, isTrue);
    // Loaded: the boxes go away and so does the animation (no leftover ticker).
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Loaded'))));
    await tester.pump(); // the swap's own last frame
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('with reduce motion, the boxes stay still', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(boxes());
    expect(find.byType(ShaderMask), findsNothing);
    expect(find.byType(Container), findsNWidgets(2));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
