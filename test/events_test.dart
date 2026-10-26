import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/screens/shared/events_screen.dart';
import 'package:michaelean_app/screens/teacher/event_form_screen.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';

Future<void> signIn(WidgetTester tester, String role) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final campus = MockCampusService(delay: Duration.zero);
  await tester.pumpWidget(MichaeleanApp(
    userService: MockUserService(),
    homeService: MockHomeService(delay: Duration.zero, campus: campus),
    campusService: campus,
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text(role));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign in with Microsoft (preview)'));
  await tester.pumpAndSettle();
}

Future<void> go(WidgetTester tester, String path) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).push(path);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('student: discover, filter, register once, then My events', (tester) async {
    await signIn(tester, 'Student');
    await tester.tap(find.text('Student Life'));
    await tester.pumpAndSettle();
    // On days with classes the Class section is taller: scroll to the link first.
    await tester.ensureVisible(find.bySemanticsLabel('See all Events'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('See all Events'));
    await tester.pumpAndSettle();

    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Dance Company Showcase'), findsNothing); // not a member
    await tester.ensureVisible(find.text('My Orgs')); // the filter row scrolls sideways
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Orgs'));
    await tester.pumpAndSettle();
    expect(find.text('CSS General Assembly'), findsOneWidget);
    // Scoped: the Student Life page behind this one lists events too.
    final onPage = find.descendant(
        of: find.byType(EventsScreen), matching: find.text('Intramurals Opening Ceremony'));
    expect(onPage, findsNothing); // school-wide
    expect(find.text('Closed'), findsOneWidget); // the coding challenge's deadline passed

    await tester.tap(find.text('CSS General Assembly'));
    await tester.pumpAndSettle();
    expect(find.text('Venue'), findsOneWidget);
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    expect(find.textContaining('preview only'), findsOneWidget);
    expect(find.text("You're registered"), findsOneWidget);
    expect(find.text('Register'), findsNothing); // can't register twice

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My events'));
    await tester.pumpAndSettle();
    expect(find.text('CSS General Assembly'), findsOneWidget);
    expect(find.text('Going'), findsWidgets);
    expect(find.text('Past'), findsOneWidget);
  });

  testWidgets('student: a full event offers no registration', (tester) async {
    await signIn(tester, 'Student');
    await go(tester, '/life/events/ev5');
    expect(find.text('This event is full.'), findsOneWidget);
    final register = find.ancestor(of: find.text('Register'), matching: find.byType(InkWell));
    expect(tester.widget<InkWell>(register).onTap, isNull);
  });

  testWidgets('teacher: create and publish, then invite a section', (tester) async {
    await signIn(tester, 'Teacher');
    await go(tester, '/life/events');
    expect(find.text('Events You Manage'), findsOneWidget);
    await tester.tap(find.text('Drafts'));
    await tester.pumpAndSettle();
    expect(find.text('Intro to Flutter Workshop'), findsOneWidget);

    await tester.tap(find.byTooltip('Create event'));
    await tester.pumpAndSettle();
    final publish = find.widgetWithText(FilledButton, 'Publish');
    expect(tester.widget<FilledButton>(publish).onPressed, isNull); // no name yet

    await tester.enterText(find.byType(TextField).at(0), 'Mock Hackathon');
    await tester.enterText(find.byType(TextField).at(1), 'Saint Theodore Hall · Lab 1');
    await tester.pump();
    await tester.tap(publish);
    await tester.pumpAndSettle();
    expect(find.textContaining('Published in this preview only'), findsOneWidget);
    expect(find.byType(EventFormScreen, skipOffstage: false), findsNothing);

    await tester.tap(find.text('Upcoming'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Mock Hackathon'), 200);
    await tester.tap(find.text('Mock Hackathon'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invite'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BSCS 3B'));
    await tester.pump(const Duration(seconds: 5)); // the publish snackbar goes away
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invite Section'));
    await tester.pumpAndSettle();
    expect(find.textContaining('12 students registered in this preview only'), findsOneWidget);
    // Teachers see everyone named: two names, then the other ten.
    final going = find.textContaining('and 10 others are going');
    await tester.scrollUntilVisible(going, 200);
    expect(going, findsOneWidget);
  });

  testWidgets("a teacher can't edit an event they don't manage", (tester) async {
    await signIn(tester, 'Teacher');
    await go(tester, '/life/events/ev1/edit');
    expect(find.text("You can't edit this event."), findsOneWidget);
  });
}
