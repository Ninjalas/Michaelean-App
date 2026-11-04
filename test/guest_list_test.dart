import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/mock/mock_users.dart';
import 'package:michaelean_app/models/guest.dart';
import 'package:michaelean_app/models/user_profile.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';

// A fixed morning, so the sample events are always upcoming.
MockCampusService newService() =>
    MockCampusService(delay: Duration.zero, clock: () => DateTime(2026, 10, 20, 10, 0));

Future<void> expectProblem(Future<void> action, RegistrationProblem problem) => expectLater(
      action,
      throwsA(isA<RegistrationException>().having((e) => e.problem, 'problem', problem)),
    );

Future<void> signIn(WidgetTester tester, String role, {bool fail = false}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final campus = MockCampusService(delay: Duration.zero, fail: fail);
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
  group('registration rules', () {
    test('registering adds the student once; a second try is refused', () async {
      final s = newService();
      final before = (await s.loadGuestSummary(mockStudent, 'ev1'))!;
      expect(before.count, 9);
      expect(before.state, RegistrationState.open);
      expect(before.canViewList, isFalse);

      await s.registerForEvent(mockStudent, 'ev1', course: 'Nursing', yearLevel: '3rd Year');
      final after = (await s.loadGuestSummary(mockStudent, 'ev1'))!;
      expect(after.count, 10);
      expect(after.state, RegistrationState.registered);
      expect(after.canViewList, isTrue);

      await expectProblem(
        s.registerForEvent(mockStudent, 'ev1', course: 'Nursing', yearLevel: '3rd Year'),
        RegistrationProblem.alreadyRegistered,
      );
      expect((await s.loadGuestSummary(mockStudent, 'ev1'))!.count, 10);
    });

    test('course and year level must be one of the dropdown choices', () async {
      final s = newService();
      await expectProblem(
        s.registerForEvent(mockStudent, 'ev1', course: 'Basket Weaving', yearLevel: '3rd Year'),
        RegistrationProblem.invalidCourse,
      );
      await expectProblem(
        s.registerForEvent(mockStudent, 'ev1', course: 'Nursing', yearLevel: '9th Year'),
        RegistrationProblem.invalidYear,
      );
      expect((await s.loadGuestSummary(mockStudent, 'ev1'))!.count, 9); // nobody was added
    });

    test('full, ineligible, draft, and unknown events are refused', () async {
      final s = newService();
      Future<void> register(UserProfile user, String id) =>
          s.registerForEvent(user, id, course: 'Nursing', yearLevel: '3rd Year');

      await expectProblem(register(mockStudent, 'ev4'), RegistrationProblem.full);
      await expectProblem(register(mockStudent, 'ev6'), RegistrationProblem.notEligible);
      await expectProblem(register(mockTeacher, 'ev7'), RegistrationProblem.closed); // draft
      await expectProblem(register(mockStudent, 'nope'), RegistrationProblem.notFound);
    });

    test('the summary reports full and closed, and hides events from ineligible users',
        () async {
      final s = newService();
      final full = (await s.loadGuestSummary(mockStudent, 'ev4'))!;
      expect(full.state, RegistrationState.full);
      expect(full.capacity, 6);
      expect((await s.loadGuestSummary(mockTeacher, 'ev7'))!.state, RegistrationState.closed);
      expect(await s.loadGuestSummary(mockStudent, 'ev6'), isNull); // Dance Company only
      expect(await s.loadEvent(mockStudent, 'ev7'), isNull); // a draft isn't visible to students
    });

    test('cancelling frees the spot; cancelling twice is refused', () async {
      final s = newService();
      await s.registerForEvent(mockStudent, 'ev1', course: 'Nursing', yearLevel: '3rd Year');
      await s.cancelRegistration(mockStudent, 'ev1');
      expect((await s.loadGuestSummary(mockStudent, 'ev1'))!.count, 9);
      expect(await s.loadGuests(mockStudent, 'ev1'), isNull);
      await expectProblem(
          s.cancelRegistration(mockStudent, 'ev1'), RegistrationProblem.notRegistered);
    });
  });

  group('guest list visibility', () {
    test('only registered guests and event managers can see the list', () async {
      final s = newService();
      expect(await s.loadGuests(mockStudent, 'ev1'), isNull); // not registered

      await s.registerForEvent(mockStudent, 'ev1', course: 'Nursing', yearLevel: '3rd Year');
      final list = (await s.loadGuests(mockStudent, 'ev1'))!;
      expect(list.length, 10);
      final me = list.firstWhere((g) => g.id == mockStudent.id);
      expect(me.course, 'Nursing');
      final names = list.map((g) => g.name.toLowerCase()).toList();
      expect(names, [...names]..sort()); // A–Z

      // The teacher manages ev2, so they can see its list without registering.
      expect((await s.loadGuests(mockTeacher, 'ev2'))!.length, 7);
      // A student who isn't registered for ev2 can't.
      expect(await s.loadGuests(mockStudent, 'ev2'), isNull);
      // Nobody gets a list for an event they can't see.
      expect(await s.loadGuests(mockStudent, 'ev6'), isNull);
    });
  });

  group('screens', () {
    testWidgets('student registers from the event page and finds themselves on the list',
        (tester) async {
      await signIn(tester, 'Student');
      await go(tester, '/life/events/ev1');
      final page = find.byType(Scrollable).first;

      expect(find.text('CSS General Assembly'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('9 going'), 200, scrollable: page);

      await tester.scrollUntilVisible(find.widgetWithText(FilledButton, 'Register'), -200,
          scrollable: page);
      await tester.tap(find.widgetWithText(FilledButton, 'Register'));
      await tester.pumpAndSettle();
      expect(find.text('Event registration'), findsOneWidget);

      // Course and year start from the student's program, as dropdowns.
      expect(find.text('BS Computer Science'), findsOneWidget);
      expect(find.text('3rd Year'), findsOneWidget);
      await tester.tap(find.text('BS Computer Science'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nursing').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm registration'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Registered in this preview only'), findsOneWidget);
      expect(find.text("You're registered"), findsOneWidget);

      await tester.scrollUntilVisible(find.text('10 going'), 200, scrollable: page);
      await tester.tap(find.text('10 going'));
      await tester.pumpAndSettle();
      expect(find.text('10 Guests'), findsOneWidget);
      expect(find.text('Nicolas Santos'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
      expect(find.text('Nursing · 3rd Year'), findsOneWidget);
    });

    testWidgets('someone who is not registered is asked to register first', (tester) async {
      await signIn(tester, 'Student');
      await go(tester, '/life/events/ev1/guests');

      expect(find.text('Register to view the guest list'), findsOneWidget);
      expect(find.text('Angelo Reyes'), findsNothing); // no names leak
      await tester.tap(find.widgetWithText(FilledButton, 'Register'));
      await tester.pumpAndSettle();
      expect(find.text('Event registration'), findsOneWidget);
    });

    testWidgets('a full event cannot be registered for', (tester) async {
      await signIn(tester, 'Student');
      await go(tester, '/life/events/ev4');

      final button = find.widgetWithText(FilledButton, 'Event full');
      expect(button, findsOneWidget);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      await tester.scrollUntilVisible(find.text('6 of 6 going'), 200,
          scrollable: find.byType(Scrollable).first);
    });

    testWidgets('a teacher manages ev2 and can search its guest list', (tester) async {
      await signIn(tester, 'Teacher');
      await go(tester, '/life/events/ev2/guests');

      expect(find.text('7 Guests'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('No results'), findsOneWidget);
    });

    testWidgets('a load failure shows Retry, never fake content', (tester) async {
      await signIn(tester, 'Student', fail: true);
      await go(tester, '/life/events/ev1');

      expect(find.text("Couldn't load this event"), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
