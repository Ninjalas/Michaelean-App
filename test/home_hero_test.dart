// Home with the navy hero (spec §2.1, direction B): the stats card hangs
// over the navy, Up next is white with a red accent, a compact navy bar
// appears once the greeting has scrolled away, and task rows have icon tiles.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';
import 'package:michaelean_app/theme/app_theme.dart';
import 'package:michaelean_app/widgets/navy_hero.dart';
import 'package:michaelean_app/widgets/stats_row.dart';
import 'package:michaelean_app/widgets/user_avatar.dart';

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

final navy = find.descendant(
    of: find.byType(NavyHero),
    matching: find.byWidgetPredicate((w) => w is ColoredBox && w.color == AppColors.navy));

void main() {
  testWidgets('student Home: navy hero, stats hanging over it, white Up next', (tester) async {
    await signIn(tester, 'Student');
    expect(find.byType(NavyHero), findsOneWidget);
    expect(tester.getTopLeft(navy).dy, 0); // from the very top
    // The greeting is white on the navy.
    final greeting = tester.widget<Text>(find.textContaining('Nicolas').first);
    expect(greeting.style?.color, AppColors.white);
    // The stats card starts on the navy and ends below it.
    final stats = tester.getRect(find.byType(StatsRow));
    final navyBottom = tester.getBottomLeft(navy).dy;
    expect(stats.top, lessThan(navyBottom));
    expect(stats.bottom, greaterThan(navyBottom));
    // Up next: a red label on a white card (Home's one navy hero is the header).
    expect(tester.widget<Text>(find.text('UP NEXT')).style?.color, AppColors.red);
    // Pending tasks have navy icon tiles (clearance tasks here).
    expect(find.byIcon(Icons.fact_check_outlined), findsWidgets);
  });

  testWidgets('a compact navy bar appears once the greeting scrolls away', (tester) async {
    await signIn(tester, 'Student');
    expect(find.byKey(const ValueKey('compact-bar')), findsNothing);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('compact-bar')), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('compact-bar')), findsNothing);
  });

  testWidgets('Profile: the photo hangs half over the navy; Settings sits on it', (tester) async {
    await signIn(tester, 'Student');
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(NavyHero), findsOneWidget);
    final photo = tester.getRect(find.descendant(
        of: find.byType(NavyHero), matching: find.byType(UserAvatar)));
    final navyBottom = tester.getBottomLeft(navy).dy;
    expect(photo.top, lessThan(navyBottom));
    expect(photo.bottom, greaterThan(navyBottom));
    expect(tester.getBottomLeft(find.byTooltip('Settings')).dy, lessThan(navyBottom));
    // The name follows below the photo.
    expect(tester.getTopLeft(find.text('Nicolas Santos')).dy, greaterThan(photo.bottom));
  });

  testWidgets('teacher Home: today at a glance hangs over the navy too', (tester) async {
    await signIn(tester, 'Teacher');
    expect(find.text('Classes today'), findsOneWidget);
    expect(tester.getRect(find.byType(StatsRow)).top, lessThan(tester.getBottomLeft(navy).dy));
  });
}
