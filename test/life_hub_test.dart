import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';

Future<void> openHub(WidgetTester tester, String role, String tab, {bool fail = false}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MichaeleanApp(
    userService: MockUserService(),
    homeService: MockHomeService(delay: Duration.zero),
    campusService: MockCampusService(delay: Duration.zero, fail: fail),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text(role));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign in with Microsoft (preview)'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(tab));
  await tester.pumpAndSettle();
}

// The page's vertical list (the events strip is a second, horizontal one).
Finder get page => find.byType(Scrollable).first;

void main() {
  testWidgets('Student Life shows live previews with See all', (tester) async {
    await openHub(tester, 'Student', 'Student Life');

    expect(find.text('Your campus, beyond the classroom.'), findsOneWidget);
    expect(find.text('Class'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('CSS General Assembly'), 200, scrollable: page); // events strip
    expect(find.text('Dance Company Showcase'), findsNothing); // not a member

    await tester.scrollUntilVisible(find.text('1st Semester Clearance'), 200, scrollable: page);
    expect(find.text('1 needs correction'), findsOneWidget);
    // People sits between Organizations and Clearance: bring Organizations back.
    await tester.scrollUntilVisible(find.bySemanticsLabel('See all Organizations'), -200,
        scrollable: page);
    await tester.pumpAndSettle();
    expect(find.text('Organizations'), findsOneWidget);
    expect(find.text('Computer Science Society'), findsOneWidget);
    expect(find.text('SMCL Chorale'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('See all Organizations'));
    await tester.pumpAndSettle();
    expect(find.text('School-wide Clubs'), findsOneWidget); // the directory (Phase 8)
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Student Life'), findsWidgets); // back on the hub
  });

  testWidgets('Michaelean Life: managed events and drafts; clearance office',
      (tester) async {
    await openHub(tester, 'Teacher', 'Michaelean Life');

    expect(find.text('Teaching & Campus'), findsOneWidget);
    expect(find.text('Classes'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Intro to Flutter Workshop'), 200, scrollable: page);
    expect(find.text('Department Assembly'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);

    // Mock assumption: the teacher processes the department's clearance items.
    await tester.scrollUntilVisible(find.text('3 pending'), 200, scrollable: page);
    await tester.ensureVisible(find.text('3 pending')); // clear of the nav bar
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 pending'));
    await tester.pumpAndSettle();
    expect(find.text('Clearance Verification'), findsOneWidget);
  });

  testWidgets("Student Life's Grades card shows this semester and opens Grades",
      (tester) async {
    await openHub(tester, 'Student', 'Student Life');
    // Grades is the first section, above Class.
    expect(tester.getTopLeft(find.bySemanticsLabel('See all Grades')).dy,
        lessThan(tester.getTopLeft(find.bySemanticsLabel('See all Class')).dy));
    expect(find.text('Midterms out · 1 of 5 finals'), findsOneWidget);
    // Only GE 104 has both grades (93, 95 → 94 → 1.50).
    expect(find.text('1.50'), findsOneWidget);
    expect(find.text('GWA so far, from 1 of 5 courses · 94.00%'), findsOneWidget);
    await tester.tap(find.text('1.50'));
    await tester.pumpAndSettle();
    expect(find.text('Grades'), findsOneWidget); // the page's header
    expect(find.text('CS 302'), findsOneWidget);
  });

  testWidgets('Michaelean Life has no Grades section (teachers: nothing yet)', (tester) async {
    await openHub(tester, 'Teacher', 'Michaelean Life');
    expect(find.bySemanticsLabel('See all Grades'), findsNothing);
    await tester.scrollUntilVisible(find.bySemanticsLabel('See all Clearance'), 200, scrollable: page);
    expect(find.text('Grades'), findsNothing);
  });

  testWidgets('hub load failure shows Retry, never fake content', (tester) async {
    await openHub(tester, 'Student', 'Student Life', fail: true);
    expect(find.text("Couldn't load this page."), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('1st Semester Clearance'), findsNothing);
  });
}
