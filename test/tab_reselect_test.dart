// Tapping the current tab again: back to its first page, then a glide to
// the top. Animated, except with the phone's "reduce motion" setting.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';

Future<void> signIn(WidgetTester tester) async {
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
  await tester.tap(find.text('Sign in with Microsoft (preview)')); // Student is preselected
  await tester.pumpAndSettle();
}

/// How far the showing page's main list is scrolled.
double offset(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).first).position.pixels;

Future<void> scrollDown(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -1500));
  await tester.pumpAndSettle();
  expect(offset(tester), greaterThan(500));
}

void main() {
  testWidgets('tapping Home again glides back to the top', (tester) async {
    await signIn(tester);
    await scrollDown(tester);

    await tester.tap(find.text('Home'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final midway = offset(tester);
    expect(midway, greaterThan(0)); // still moving: it's a glide, not a jump
    await tester.pumpAndSettle();
    expect(offset(tester), 0);
    expect(find.textContaining(', Nicolas'), findsWidgets); // the greeting is back
  });

  testWidgets('on an inner page, the first tap goes back; the next goes to the top',
      (tester) async {
    await signIn(tester);
    await scrollDown(tester);
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/home/post/a1');
    await tester.pumpAndSettle();
    expect(find.textContaining('not an official announcement'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.textContaining('not an official announcement'), findsNothing); // back on Home
    expect(offset(tester), greaterThan(500)); // where you left it

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(offset(tester), 0);
  });

  testWidgets('Student Life and Profile scroll to the top too', (tester) async {
    await signIn(tester);
    for (final tab in ['Student Life', 'Profile']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      await scrollDown(tester);
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(offset(tester), 0, reason: tab);
    }
  });

  testWidgets('with reduce motion on, it goes to the top at once', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await signIn(tester);
    await scrollDown(tester);

    await tester.tap(find.text('Home'));
    await tester.pump(); // a single frame
    expect(offset(tester), 0);
  });
}
