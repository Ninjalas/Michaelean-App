// Phase 10 audit: every screen, both roles, on a small phone with large
// text (no overflow or crash), on a normal phone against Flutter's
// accessibility guidelines, and with a failing service (an error, never a
// crash or fake content).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';

/// A future Tuesday's CS 302 session: not open yet, so nothing is seeded.
String _nextTuesdaySession() {
  var d = DateTime.now();
  do {
    d = DateTime(d.year, d.month, d.day + 1);
  } while (d.weekday != DateTime.tuesday);
  String two(int n) => n.toString().padLeft(2, '0');
  return 'cs302-3a@${d.year}-${two(d.month)}-${two(d.day)}';
}

const studentRoutes = [
  '/home',
  '/home/notifications',
  '/qr',
  '/life',
  '/life/class',
  '/life/events',
  '/life/events/ev1',
  '/life/events/ev5',
  '/life/organizations',
  '/life/organizations/org1',
  '/life/organizations/org3',
  '/life/organizations/org1/post/o2',
  '/life/clearance',
  '/life/clearance/lib',
  '/life/clearance/dcs-lab',
  '/profile',
  '/profile/settings',
  '/profile/edit',
];

List<String> teacherRoutes() {
  final session = _nextTuesdaySession();
  return [
    '/home',
    '/life',
    '/life/classes',
    '/life/classes/cs302-3a',
    '/life/classes/cs302-3a/edit?session=$session',
    '/attendance/$session',
    '/attendance/$session/review',
    '/life/events',
    '/life/events/new',
    '/life/events/ev2',
    '/life/events/ev2/edit',
    '/life/events/ev2/invite',
    '/life/events/ev2/registrations',
    '/life/verify',
    '/life/verify/mock-student-1',
    '/profile',
  ];
}

Future<void> signIn(WidgetTester tester, String role, {bool fail = false}) async {
  final campus = MockCampusService(delay: Duration.zero, fail: fail);
  await tester.pumpWidget(MichaeleanApp(
    userService: MockUserService(),
    homeService: MockHomeService(delay: Duration.zero, fail: fail, campus: campus),
    campusService: campus,
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text(role));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign in with Microsoft (preview)'));
  await tester.pumpAndSettle();
}

Future<void> visit(WidgetTester tester, String path) async {
  GoRouter.of(tester.element(find.byType(Navigator).first)).go(path);
  await tester.pumpAndSettle();
}

/// Scrolls the page to the bottom so lazily built rows are laid out too.
Future<void> scrollThrough(WidgetTester tester) async {
  final vertical = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
  if (vertical.evaluate().isEmpty) return;
  for (var i = 0; i < 4; i++) {
    await tester.drag(vertical.first, const Offset(0, -600), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

void main() {
  for (final role in ['Student', 'Teacher']) {
    testWidgets('$role: every screen fits a small phone with large text', (tester) async {
      tester.view.physicalSize = const Size(320, 568); // a small phone
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await signIn(tester, role);
      final problems = <String>[];
      var path = '';
      // Record each layout error with the widget that caused it.
      final original = FlutterError.onError;
      FlutterError.onError = (details) {
        final where = RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(details.toString())?[0];
        problems.add('$path: ${details.exceptionAsString().split('\n').first} ($where)');
      };
      for (path in role == 'Student' ? studentRoutes : teacherRoutes()) {
        await visit(tester, path);
        await scrollThrough(tester);
      }
      FlutterError.onError = original;
      expect(problems, isEmpty);
    });

    testWidgets('$role: every screen meets tap-target and label guidelines', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();

      await signIn(tester, role);
      final problems = <String>[];
      for (final path in role == 'Student' ? studentRoutes : teacherRoutes()) {
        await visit(tester, path);
        for (final g in [androidTapTargetGuideline, labeledTapTargetGuideline]) {
          final result = await g.evaluate(tester);
          if (!result.passed) problems.add('$path: ${result.reason}');
        }
      }
      semantics.dispose();
      expect(problems, isEmpty);
    });

    testWidgets('$role: a failing service shows an error, never a crash', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await signIn(tester, role, fail: true);
      final problems = <String>[];
      for (final path in role == 'Student' ? studentRoutes : teacherRoutes()) {
        // These load no service data.
        if (path == '/qr' || path == '/life/events/new' || path.startsWith('/profile')) continue;
        await visit(tester, path);
        final e = tester.takeException();
        if (e != null) problems.add('$path: crashed: $e');
        if (find.textContaining("Couldn't").evaluate().isEmpty) {
          problems.add('$path: no error message');
        }
      }
      expect(problems, isEmpty);
    });
  }
}
