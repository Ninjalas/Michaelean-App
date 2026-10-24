// Pages slide in from the right on every platform (Android here, the test
// default) and simply appear with the phone's "reduce motion" setting.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/theme/app_theme.dart';

Widget app() => MaterialApp(
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Next page')))),
            child: const Text('Open'),
          ),
        ),
      ),
    );

double pageLeft(WidgetTester tester) => tester.getTopLeft(find.text('Next page')).dx;

void main() {
  testWidgets('a new page slides in from the right', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(pageLeft(tester), inExclusiveRange(0, 390)); // on its way in
    await tester.pumpAndSettle();
    expect(pageLeft(tester), 0);
  });

  testWidgets('with reduce motion, the page appears at once', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(app());
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(pageLeft(tester), 0);
  });
}
