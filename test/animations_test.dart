// Animations, step 2: content fades in after loading, and tabs fade when
// switched. Instant with the phone's "reduce motion" setting.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/screens/shared/app_shell.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';
import 'package:michaelean_app/widgets/fade_switch.dart';

Widget host(bool loaded, String text) => MaterialApp(
      home: Scaffold(body: FadeSwitch(loaded: loaded, child: Text(text))),
    );

void main() {
  testWidgets('loading fades into the content', (tester) async {
    await tester.pumpWidget(host(false, 'Loading'));
    await tester.pumpWidget(host(true, 'Content'));
    await tester.pump(const Duration(milliseconds: 100));
    // Midway, both are there: one fading out, the other fading in.
    expect(find.text('Loading'), findsOneWidget);
    expect(find.text('Content'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Loading'), findsNothing);
    expect(find.text('Content'), findsOneWidget);
  });

  testWidgets('a reload updates the content in place, without fading', (tester) async {
    await tester.pumpWidget(host(true, 'Old'));
    await tester.pumpWidget(host(true, 'New'));
    expect(find.text('Old'), findsNothing); // replaced at once
    expect(find.text('New'), findsOneWidget);
  });

  testWidgets('with reduce motion, the content appears at once', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(host(false, 'Loading'));
    await tester.pumpWidget(host(true, 'Content'));
    await tester.pump();
    expect(find.text('Loading'), findsNothing);
  });

  testWidgets('switching tabs fades the new tab in', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final campus = MockCampusService(delay: Duration.zero);
    await tester.pumpWidget(MichaeleanApp(
      userService: MockUserService(campus: campus),
      homeService: MockHomeService(delay: Duration.zero, campus: campus),
      campusService: campus,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open preview'));
    await tester.pumpAndSettle();

    // The tab area's fade (the first one inside the app frame).
    double opacity() => tester
        .widget<FadeTransition>(
            find.descendant(of: find.byType(AppShell), matching: find.byType(FadeTransition)).first)
        .opacity
        .value;
    expect(opacity(), 1);
    await tester.tap(find.text('Profile'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(opacity(), allOf(greaterThan(0), lessThan(1))); // fading in
    await tester.pumpAndSettle();
    expect(opacity(), 1);
  });
}
