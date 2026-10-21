import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/screens/student/organization_screen.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';

Future<void> signInStudent(WidgetTester tester) async {
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
  await tester.tap(find.text('Sign in with Microsoft (preview)')); // Student is preselected
  await tester.pumpAndSettle();
  await tester.tap(find.text('Student Life'));
  await tester.pumpAndSettle();
  // Scroll until the section below is in view, so the link is clear of the nav bar.
  await tester.scrollUntilVisible(find.text('1st Semester Clearance'), 200,
      scrollable: find.byType(Scrollable).first);
  await tester.tap(find.bySemanticsLabel('See all Organizations'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('directory groups; an organization event opens and Back returns', (tester) async {
    await signInStudent(tester);
    expect(find.text('Your Department Society'), findsOneWidget);
    expect(find.text('School-wide Clubs'), findsOneWidget);
    expect(find.text('Nursing Students Association'), findsNothing);

    await tester.tap(find.text('Computer Science Society').first);
    await tester.pumpAndSettle();
    expect(find.text('Departmental society'), findsOneWidget);
    expect(find.text('Request to Join'), findsNothing); // already a member

    await tester.ensureVisible(find.text('Officers')); // the tab row scrolls sideways
    await tester.pumpAndSettle();
    await tester.tap(find.text('Officers'));
    await tester.pumpAndSettle();
    expect(find.text('President'), findsOneWidget);

    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('CSS General Assembly'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('CSS General Assembly'));
    await tester.pumpAndSettle();
    expect(find.text('Venue'), findsOneWidget); // the shared event page

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(OrganizationScreen), findsOneWidget);
    expect(find.text('CSS General Assembly'), findsOneWidget); // still on the Events tab
  });

  testWidgets('request to join is honest: saved here, not a member', (tester) async {
    await signInStudent(tester);
    await tester.scrollUntilVisible(find.text('Dance Company'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Dance Company'));
    await tester.pumpAndSettle();
    expect(find.text('Some events and posts are for members only.'), findsOneWidget);

    await tester.tap(find.text('Request to Join'));
    await tester.pumpAndSettle();
    expect(find.textContaining("Nothing was sent, and you're not a member yet."), findsOneWidget);
    expect(find.text('Request saved'), findsOneWidget);
    expect(find.text('Member'), findsNothing);
  });
}
