// Connect, step 2 (spec §10.1): other students' profiles, the Connect
// buttons, blocking, and the Connections section on Profile.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/mock/mock_users.dart';
import 'package:michaelean_app/models/user_profile.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';
import 'package:michaelean_app/widgets/person_row.dart';

Future<void> signIn(WidgetTester tester, String role, MockCampusService campus) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MichaeleanApp(
    userService: MockUserService(campus: campus),
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

/// Scrolls the page until [finder] is on screen and clear of the nav bar.
Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).last);
  await tester.drag(find.byType(Scrollable).last, const Offset(0, -150));
  await tester.pumpAndSettle();
}

UserProfile asStudent(String id, String first, String last) => UserProfile(
      id: id,
      role: UserRole.student,
      firstName: first,
      lastName: last,
      designation: '',
      maskedId: '',
      email: '',
      qrToken: '',
      tags: const [],
    );

void main() {
  late MockCampusService campus;
  setUp(() => campus = MockCampusService(delay: Duration.zero));

  testWidgets('Profile lists connections and requests; accepting connects', (tester) async {
    await signIn(tester, 'Student', campus);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Connections (4)'), 200,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('Requests (2)', skipOffstage: false), findsOneWidget);

    await tester.scrollUntilVisible(find.byTooltip('Accept Bea Villareal'), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.ensureVisible(find.byTooltip('Accept Bea Villareal')); // to the top, clear of the nav bar
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Accept Bea Villareal'));
    await tester.pumpAndSettle();
    expect(find.text('Connected in this preview only.'), findsOneWidget);
    expect(find.text('Connections (5)', skipOffstage: false), findsOneWidget);
    expect(find.text('Requests (1)', skipOffstage: false), findsOneWidget);
  });

  testWidgets("a connection's profile shows what Connections may see", (tester) async {
    await signIn(tester, 'Student', campus);
    await go(tester, '/profile/people/stu-BSCS3A2'); // Carlo, default settings
    expect(find.text('Carlo Mendoza'), findsWidgets);
    expect(find.text('Connected'), findsOneWidget);
    await reveal(tester, find.text('Event History'));
    expect(find.textContaining('Hidden by'), findsNothing);
  });

  testWidgets('a stranger: Connect, then Pending; private parts hidden', (tester) async {
    await signIn(tester, 'Student', campus);
    await go(tester, '/life/people/stu-BSCS3B3'); // Celine
    await reveal(tester, find.text('Event History'));
    expect(find.text("Hidden by Celine's privacy settings."), findsNWidgets(3));

    await tester.drag(find.byType(Scrollable).last, const Offset(0, 1000)); // back to the top
    await tester.pumpAndSettle();
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    expect(find.text('Request sent in this preview only.'), findsOneWidget);
    expect(find.text('Pending · Cancel request'), findsOneWidget);
  });

  testWidgets('block from the ⋯ menu, then unblock', (tester) async {
    await signIn(tester, 'Student', campus);
    await go(tester, '/profile/people/stu-BSCS3A1'); // Andrea, connected
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Block'));
    await tester.pumpAndSettle();
    expect(find.text('Block Andrea Bautista?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Block'));
    await tester.pumpAndSettle();
    expect(find.textContaining('You blocked Andrea.'), findsOneWidget);
    expect(find.text('Event History'), findsNothing);

    await tester.tap(find.text('Unblock'));
    await tester.pumpAndSettle();
    expect(find.text('Connect'), findsOneWidget); // the connection stays removed
  });

  testWidgets('teachers see everything and get no Connect button', (tester) async {
    await signIn(tester, 'Teacher', campus);
    await go(tester, '/life/people/stu-BSCS3A5'); // Erika: upcoming events Only me
    expect(find.text('Connect'), findsNothing);
    expect(find.byTooltip('More options'), findsNothing);
    await reveal(tester, find.text('Event History'));
    expect(find.textContaining('Hidden by'), findsNothing);
  });

  testWidgets("the bell's accepted notice opens their profile", (tester) async {
    await tester.runAsync(() async {
      await campus.sendConnectRequest(mockStudent, 'stu-BSCS3B3');
      await campus.answerConnectRequest(asStudent('stu-BSCS3B3', 'Celine', 'Yap'), mockStudent.id,
          accept: true);
    });
    await signIn(tester, 'Student', campus);
    await tester.tap(find.byTooltip(RegExp('^Notifications')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Celine Yap accepted your request to connect.'));
    await tester.pumpAndSettle();
    expect(find.text('Connected'), findsOneWidget);
  });

  testWidgets('Student Life suggests people; Connect from the list', (tester) async {
    await signIn(tester, 'Student', campus);
    await tester.tap(find.text('Student Life'));
    await tester.pumpAndSettle();
    final connect = find.widgetWithText(OutlinedButton, 'Connect');
    // The page's own list (the events strip inside it also scrolls, sideways).
    await tester.scrollUntilVisible(find.text('People'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(find.text('People'), findsOneWidget);
    final name = tester
        .widget<PersonRow>(find.ancestor(of: connect.first, matching: find.byType(PersonRow)))
        .person
        .name;
    await tester.tap(connect.first);
    await tester.pumpAndSettle();
    expect(find.text('Request sent to $name in this preview only.'), findsOneWidget);
    // Suggestions list only people you haven't asked yet.
    expect(find.text(name), findsNothing);
  });

  testWidgets('People search finds students by name', (tester) async {
    await signIn(tester, 'Student', campus);
    await go(tester, '/life/people');
    expect(find.text('People you may know'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'mendoza');
    await tester.pumpAndSettle();
    expect(find.text('Carlo Mendoza'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    await tester.tap(find.text('Carlo Mendoza'));
    await tester.pumpAndSettle();
    expect(find.text('Student · BSCS 3A'), findsOneWidget); // his profile
  });

  testWidgets('teachers browse all students, view only', (tester) async {
    await signIn(tester, 'Teacher', campus);
    await go(tester, '/life/people');
    expect(find.text('All students'), findsOneWidget);
    expect(find.text('Andrea Bautista'), findsOneWidget);
    expect(find.text('Connect'), findsNothing);
  });

  testWidgets('club pages list their members', (tester) async {
    await signIn(tester, 'Student', campus);
    await go(tester, '/life/organizations/org6'); // Robotics Club
    final tab = find.text('Members (6)');
    await tester.scrollUntilVisible(tab, 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(tab);
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Diego Ramos'));
    expect(find.text('Connected'), findsOneWidget); // Diego is Nicolas's connection
  });

  testWidgets('Settings › Privacy saves a choice; blocked students can be unblocked',
      (tester) async {
    await tester.runAsync(() => campus.blockStudent(mockStudent, 'stu-BSCS3B3'));
    await signIn(tester, 'Student', campus);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Privacy'));
    await tester.pumpAndSettle();

    // Event history: the second row of choices.
    await tester.tap(find.text('Only me').at(1));
    await tester.pumpAndSettle();
    final saved = await tester.runAsync(() => campus.loadPrivacy(mockStudent));
    expect(saved!.eventHistory.label, 'Only me');

    await reveal(tester, find.text('Celine Yap'));
    await tester.tap(find.text('Unblock'));
    await tester.pumpAndSettle();
    expect(find.text('Celine Yap unblocked in this preview only.'), findsOneWidget);
    expect(find.text("You haven't blocked anyone."), findsOneWidget);
  });

  testWidgets("teachers' Settings has no Privacy row", (tester) async {
    await signIn(tester, 'Teacher', campus);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Privacy'), findsNothing);
  });

  testWidgets("the event page shows who's going; the full list opens", (tester) async {
    await signIn(tester, 'Student', campus);
    await go(tester, '/life/events/ev3');
    final line = find.text('You, Carlo and 239 others are going');
    await reveal(tester, line);
    await tester.tap(line);
    await tester.pumpAndSettle();
    expect(find.text('Going'), findsOneWidget);
    expect(find.text('Carlo Mendoza'), findsOneWidget);
    await reveal(tester, find.textContaining("others aren't named"));
    await tester.tap(find.text('Bea Villareal'));
    await tester.pumpAndSettle();
    expect(find.text('Student · BSCS 3A'), findsOneWidget); // her profile
  });

  testWidgets('a past event shows who went', (tester) async {
    await signIn(tester, 'Student', campus);
    await go(tester, '/profile/events/past-git');
    await reveal(tester, find.text('You, Andrea and 2 others went'));
    expect(find.text('Went'), findsOneWidget);
  });

  testWidgets('teachers open a student from a class list', (tester) async {
    await signIn(tester, 'Teacher', campus);
    await go(tester, '/life/classes/cs302-3a');
    final row = find.text('Andrea Bautista');
    await tester.scrollUntilVisible(row, 200, scrollable: find.byType(Scrollable).last);
    await tester.ensureVisible(row); // to the top, clear of the nav bar
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text('Student · BSCS 3A'), findsOneWidget);
    expect(find.text('Connect'), findsNothing);
  });

  testWidgets('teachers open a student from Manage club', (tester) async {
    await signIn(tester, 'Teacher', campus);
    await go(tester, '/life/clubs/org6');
    await tester.tap(find.text('Diego Ramos'));
    await tester.pumpAndSettle();
    expect(find.text('Student · BSCS 3A'), findsOneWidget);
  });

  testWidgets('Michaelean Life has a People section for teachers', (tester) async {
    await signIn(tester, 'Teacher', campus);
    await tester.tap(find.text('Michaelean Life'));
    await tester.pumpAndSettle();
    final hint = find.text('Search any student to open their profile.');
    await tester.scrollUntilVisible(hint, 200, scrollable: find.byType(Scrollable).first);
    expect(hint, findsOneWidget);
  });

  testWidgets('accepting a request: the row folds away as it joins Connections', (tester) async {
    await signIn(tester, 'Student', campus);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    final accept = find.byTooltip('Accept Bea Villareal');
    await tester.scrollUntilVisible(accept, 200, scrollable: find.byType(Scrollable).last);
    await tester.ensureVisible(accept);
    await tester.pumpAndSettle();
    await tester.tap(accept);
    // Frame by frame: at some point she is both leaving Requests and
    // arriving in Connections.
    var most = 0;
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      final n = find.text('Bea Villareal', skipOffstage: false).evaluate().length;
      if (n > most) most = n;
    }
    expect(most, 2);
    await tester.pumpAndSettle();
    expect(find.text('Bea Villareal', skipOffstage: false), findsOneWidget);
  });
}
