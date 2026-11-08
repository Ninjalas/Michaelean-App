// Pages opened from Home (or Profile) stay in that tab, so Back returns
// where the user tapped instead of staying in Michaelean Life (decided
// 2026-10-24).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/screens/shared/home_screen.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';
import 'package:michaelean_app/widgets/content_row.dart';
import 'package:michaelean_app/widgets/floating_nav_bar.dart';

Future<void> signIn(WidgetTester tester, String role) async {
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
  await tester.tap(find.text(role));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open preview'));
  await tester.pumpAndSettle();
}

GoRouter router(WidgetTester tester) => GoRouter.of(tester.element(find.byType(Scaffold).first));

/// The top page's address, pushed pages included.
String path(WidgetTester tester) => router(tester).state.uri.path;

int selectedTab(WidgetTester tester) =>
    tester.widget<FloatingNavBar>(find.byType(FloatingNavBar)).selectedIndex;

Future<void> tap(WidgetTester tester, Finder finder) async {
  // Scroll only when needed: scrolling a Home item to the very top would put
  // it under the pinned navy bar.
  if (!tester.any(finder.hitTestable())) {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> back(WidgetTester tester) => tap(tester, find.byTooltip('Back').last);

void main() {
  testWidgets('student: Class attendance opens in Home; Back returns to Home', (tester) async {
    await signIn(tester, 'Student');
    await tap(tester, find.text('Class attendance'));
    expect(path(tester), '/home/class');
    expect(selectedTab(tester), 0); // Home stays highlighted
    await back(tester);
    expect(path(tester), '/home');
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('student: Event attendance opens Event History in Home, events too',
      (tester) async {
    await signIn(tester, 'Student');
    await tap(tester, find.text('Event attendance'));
    expect(path(tester), '/home/history');
    expect(find.text('Event History'), findsOneWidget);
    await tap(tester, find.byType(ContentRow).first);
    expect(path(tester), startsWith('/home/events/'));
    expect(selectedTab(tester), 0);
    await back(tester);
    await back(tester);
    expect(path(tester), '/home');
  });

  testWidgets('teacher: Classes today → a class → a student, Back walks home',
      (tester) async {
    await signIn(tester, 'Teacher');
    await tap(tester, find.text('Classes today'));
    expect(path(tester), '/home/classes');
    await tap(tester, find.byType(ContentRow).first);
    expect(path(tester), startsWith('/home/classes/'));
    // The first roster row (its masked ID is the row's last text).
    await tap(tester, find.textContaining('*').first);
    expect(path(tester), startsWith('/home/people/'));
    expect(selectedTab(tester), 0);
    await back(tester);
    await back(tester);
    await back(tester);
    expect(path(tester), '/home');
  });

  testWidgets('teacher: a class on Profile opens in Profile; Back returns there',
      (tester) async {
    await signIn(tester, 'Teacher');
    router(tester).go('/profile');
    await tester.pumpAndSettle();
    await tap(tester, find.text('Classes I Teach'));
    await tap(tester, find.byType(ContentRow).first);
    expect(path(tester), startsWith('/profile/classes/'));
    expect(selectedTab(tester), 2);
    await back(tester);
    expect(path(tester), '/profile');
  });

  testWidgets('Michaelean Life keeps its own pages', (tester) async {
    await signIn(tester, 'Student');
    router(tester).go('/life/events');
    await tester.pumpAndSettle();
    await tap(tester, find.byType(ContentRow).first);
    expect(path(tester), startsWith('/life/events/'));
    expect(selectedTab(tester), 1);
  });
}
