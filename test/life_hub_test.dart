import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';

Future<void> openHub(
  WidgetTester tester,
  String role,
  String tab, {
  bool fail = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MichaeleanApp(
      userService: MockUserService(),
      homeService: MockHomeService(delay: Duration.zero),
      campusService: MockCampusService(delay: Duration.zero, fail: fail),
    ),
  );
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
    await tester.scrollUntilVisible(
      find.text('CSS General Assembly'),
      200,
      scrollable: page,
    ); // events strip
    expect(find.text('Dance Company Showcase'), findsNothing); // not a member

    await tester.scrollUntilVisible(
      find.text('1st Semester Clearance'),
      200,
      scrollable: page,
    );
    expect(find.text('Organizations'), findsOneWidget);
    expect(find.text('Computer Science Society'), findsWidgets);
    expect(find.text('SMCL Chorale'), findsOneWidget);
    expect(find.text('1 needs correction'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('See all Organizations'));
    await tester.pumpAndSettle();
    expect(find.textContaining("hasn't been built yet"), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Student Life'), findsWidgets); // back on the hub
  });

  testWidgets('See all Events opens a selected event with its details', (
    tester,
  ) async {
    await openHub(tester, 'Student', 'Student Life');

    await tester.scrollUntilVisible(
      find.bySemanticsLabel('See all Events'),
      200,
      scrollable: page,
    );
    await tester.tap(find.bySemanticsLabel('See all Events'));
    await tester.pumpAndSettle();

    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Department Assembly'), findsOneWidget);
    await tester.tap(find.text('Department Assembly'));
    await tester.pumpAndSettle();

    expect(find.text("Saint Mary's Conference Center"), findsOneWidget);
    expect(find.text('42 going'), findsOneWidget);
    expect(find.textContaining('Nicolas Santos'), findsOneWidget);
    expect(find.text('No event description is available yet.'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Events'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Student Life'), findsWidgets);
  });

  testWidgets(
    'registration updates this event attendee preview and cancellation reverts it',
    (tester) async {
      await openHub(tester, 'Student', 'Student Life');
      await tester.scrollUntilVisible(
        find.bySemanticsLabel('See all Events'),
        200,
        scrollable: page,
      );
      await tester.tap(find.bySemanticsLabel('See all Events'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CSS General Assembly'));
      await tester.pumpAndSettle();

      expect(
        find.text('Attendee information is not available yet.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Register').first);
      await tester.pumpAndSettle();
      expect(find.text('EVENT REGISTRATION'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'Alex Example');
      await tester.enterText(
        find.byType(TextField).at(1),
        'BS Computer Science',
      );
      await tester.enterText(find.byType(TextField).at(2), '3rd Year');
      expect(
        find
            .byType(TextField)
            .evaluate()
            .map((element) => (element.widget as TextField).controller!.text)
            .toList(),
        ['Alex Example', 'BS Computer Science', '3rd Year'],
      );
      await tester.pumpAndSettle();
      final submitRegistration = find.widgetWithText(
        ElevatedButton,
        'Register',
      );
      expect(
        tester.widget<ElevatedButton>(submitRegistration).onPressed,
        isNotNull,
      );
      await tester.ensureVisible(submitRegistration);
      await tester.tap(submitRegistration);
      await tester.pumpAndSettle();

      expect(find.text("You're Registered!"), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('1 going'), findsOneWidget);
      expect(find.text('Alex Example'), findsOneWidget);

      await tester.tap(find.text('Registered'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel Registration'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, cancel'));
      await tester.pumpAndSettle();

      expect(
        find.text('Attendee information is not available yet.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Michaelean Life: managed events and drafts; clearance locked without permission',
    (tester) async {
      await openHub(tester, 'Teacher', 'Michaelean Life');

      expect(find.text('Teaching & Campus'), findsOneWidget);
      expect(find.text('Classes'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Intro to Flutter Workshop'),
        200,
        scrollable: page,
      );
      expect(find.text('Department Assembly'), findsOneWidget);
      expect(find.text('Draft'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('See all Events You Manage'));
      await tester.pumpAndSettle();
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Department Assembly'), findsOneWidget);
      expect(find.text('Intro to Flutter Workshop'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // Mock teacher can manage classes and events, but has no clearance area.
      await tester.scrollUntilVisible(
        find.text("You aren't assigned to a clearance area."),
        200,
        scrollable: page,
      );
      expect(find.bySemanticsLabel('See all Clearance'), findsNothing);
      await tester.tap(find.text('Clearance'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining("hasn't been built yet"),
        findsNothing,
      ); // didn't navigate
      expect(
        find.text("You aren't assigned to a clearance area."),
        findsOneWidget,
      );
    },
  );

  testWidgets('hub load failure shows Retry, never fake content', (
    tester,
  ) async {
    await openHub(tester, 'Student', 'Student Life', fail: true);
    expect(find.text("Couldn't load this page."), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('1st Semester Clearance'), findsNothing);
  });
}
