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
    expect(find.text('Organizations'), findsOneWidget);
    expect(find.text('Computer Science Society'), findsOneWidget);
    expect(find.text('SMCL Chorale'), findsOneWidget);
    expect(find.text('1 needs correction'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('See all Organizations'));
    await tester.pumpAndSettle();
    expect(find.textContaining("hasn't been built yet"), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Student Life'), findsWidgets); // back on the hub
  });

  testWidgets('Michaelean Life: managed events and drafts; clearance locked without permission',
      (tester) async {
    await openHub(tester, 'Teacher', 'Michaelean Life');

    expect(find.text('Teaching & Campus'), findsOneWidget);
    expect(find.text('Classes'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Intro to Flutter Workshop'), 200, scrollable: page);
    expect(find.text('Department Assembly'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);

    // Mock teacher can manage classes and events, but has no clearance area.
    await tester.scrollUntilVisible(find.text("You aren't assigned to a clearance area."), 200,
        scrollable: page);
    expect(find.bySemanticsLabel('See all Clearance'), findsNothing);
    await tester.tap(find.text('Clearance'));
    await tester.pumpAndSettle();
    expect(find.textContaining("hasn't been built yet"), findsNothing); // didn't navigate
    expect(find.text("You aren't assigned to a clearance area."), findsOneWidget);
  });

  testWidgets('hub load failure shows Retry, never fake content', (tester) async {
    await openHub(tester, 'Student', 'Student Life', fail: true);
    expect(find.text("Couldn't load this page."), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('1st Semester Clearance'), findsNothing);
  });
}
