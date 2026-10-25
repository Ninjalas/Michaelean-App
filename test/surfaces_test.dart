// New look, step 5 (spec §2.1): list pages keep their rows together in
// white cards on the soft page.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';
import 'package:michaelean_app/widgets/surface_card.dart';

Future<void> open(WidgetTester tester, String path) async {
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
  await tester.tap(find.text('Sign in with Microsoft (preview)'));
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).push(path);
  await tester.pumpAndSettle();
}

Finder inCard(String text) =>
    find.descendant(of: find.byType(SurfaceCard), matching: find.text(text));

void main() {
  testWidgets('Events: each day in its own card', (tester) async {
    await open(tester, '/life/events');
    expect(inCard('CSS General Assembly'), findsOneWidget);
    expect(find.byType(SurfaceCard), findsWidgets);
  });

  testWidgets('Organizations, Clearance and Grades keep rows in cards', (tester) async {
    await open(tester, '/life/organizations');
    expect(inCard('SMCL Chorale'), findsWidgets);
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    router.push('/life/clearance');
    await tester.pumpAndSettle();
    expect(inCard('Library'), findsOneWidget);
    router.push('/life/grades');
    await tester.pumpAndSettle();
    expect(inCard('CS 302'), findsOneWidget);
  });
}
