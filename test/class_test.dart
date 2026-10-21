import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/screens/teacher/attendance_review_screen.dart';
import 'package:michaelean_app/screens/teacher/attendance_scan_screen.dart';
import 'package:michaelean_app/screens/teacher/edit_session_screen.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';
import 'package:michaelean_app/utils/dates.dart';

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

/// A future Tuesday, when CS 302 meets: not seeded, not open yet.
String nextTuesdayId() {
  var d = DateTime.now();
  do {
    d = DateTime(d.year, d.month, d.day + 1);
  } while (d.weekday != DateTime.tuesday);
  String two(int n) => n.toString().padLeft(2, '0');
  return 'cs302-3a@${d.year}-${two(d.month)}-${two(d.day)}';
}

void main() {
  testWidgets('student Class: attendance, scrollable schedule, records of the chosen day',
      (tester) async {
    await signIn(tester, 'Student');
    await tester.tap(find.text('Student Life'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('See all Class'));
    await tester.pumpAndSettle();

    // 1. Attendance this semester: overall and by subject.
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.textContaining('this semester'), findsOneWidget);
    expect(find.text('By subject'), findsOneWidget);

    // 2. Schedule: the day strip scrolls through the semester.
    final page = find.byType(Scrollable).first; // the page; the strip is a second one
    final strip = find.byKey(const Key('day-strip'));
    // Scroll until the heading below the strip shows, so the strip is clear of the nav bar.
    await tester.scrollUntilVisible(find.text('Records'), 300, scrollable: page);
    expect(find.text('Schedule'), findsOneWidget);

    DateTime classDay(int offset) {
      var d = DateTime.now();
      d = DateTime(d.year, d.month, d.day + offset);
      while (d.weekday == DateTime.sunday) {
        d = DateTime(d.year, d.month, d.day + offset.sign);
      }
      return d;
    }

    String label(DateTime d) => '${weekdayName(d)} ${formatDayMonth(d)}';

    // 3. A past day: its records are finalized, so each class shows a mark.
    final past = classDay(-1);
    await tester.tap(find.bySemanticsLabel(RegExp('^${label(past)}')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Records'), 300, scrollable: page);
    expect(find.text('${weekdayName(past)}, ${formatDayMonth(past)}'), findsOneWidget);
    expect(find.text('Present').evaluate().length + find.text('Absent').evaluate().length,
        greaterThan(0));
    expect(find.text('Upcoming'), findsNothing);

    // A future day: nothing is marked yet.
    await tester.scrollUntilVisible(find.text('Schedule'), -300, scrollable: page);
    final future = classDay(2);
    await tester.tap(find.bySemanticsLabel(RegExp('^${label(future)}')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Records'), 300, scrollable: page);
    expect(find.text('Upcoming'), findsWidgets);
    expect(find.text('Present'), findsNothing);

    // Scrolling far ahead shows weeks beyond the current one.
    await tester.scrollUntilVisible(find.text('Schedule'), -300, scrollable: page);
    final farAhead = find.bySemanticsLabel(RegExp('^${label(classDay(28))}'));
    expect(farAhead, findsNothing); // four weeks ahead: not built until scrolled to
    await tester.scrollUntilVisible(farAhead, 200,
        scrollable: find.descendant(of: strip, matching: find.byType(Scrollable)));
    expect(farAhead, findsOneWidget);
    await tester.tap(farAhead); // select it, so "Today" appears
    await tester.pumpAndSettle();

    // "Today" brings the strip back.
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsNothing); // today is selected again

    await tester.scrollUntilVisible(find.text('Show QR'), -300, scrollable: page);
    await tester.tap(find.text('Show QR'));
    await tester.pumpAndSettle();
    expect(find.text('Your QR code'), findsOneWidget);
  });

  testWidgets('scan flow: flash, counter, rules, review, finalize (preview only)',
      (tester) async {
    await signIn(tester, 'Teacher');
    final id = nextTuesdayId();
    await go(tester, '/attendance/$id');

    expect(find.text('MOCK SCANNER · no camera is used'), findsOneWidget);
    expect(find.textContaining('Attendance opens at'), findsOneWidget); // not open yet
    expect(find.text('Simulate scan'), findsNothing);

    await tester.tap(find.text('Open anyway (preview tool)'));
    await tester.pumpAndSettle();
    expect(find.text('Present 0 · Unchecked 12'), findsOneWidget);

    await tester.tap(find.text('Simulate scan'));
    await tester.pump(); // flash is up
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Nicolas Santos'), findsOneWidget);
    expect(find.text('Present'), findsOneWidget);
    expect(find.text('Present 1 · Unchecked 11'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2)); // flash timer ends…
    await tester.pumpAndSettle(); // …and the card fades out
    expect(find.text('Nicolas Santos'), findsNothing);

    await tester.tap(find.text('Unknown code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Not on this class roster. Not marked.'), findsOneWidget);
    expect(find.text('Present 1 · Unchecked 11'), findsOneWidget); // unchanged
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect(find.text('Review Attendance'), findsOneWidget);
    expect(find.text('Unchecked students will be marked Absent when you finalize.'),
        findsOneWidget);

    await tester.tap(find.text('Confirm finalization'));
    await tester.pumpAndSettle();
    expect(find.textContaining('preview only. Not an official record.'), findsOneWidget);
    // Both the review and the scanner under it are gone, not just hidden.
    expect(find.byType(AttendanceReviewScreen, skipOffstage: false), findsNothing);
    expect(find.byType(AttendanceScanScreen, skipOffstage: false), findsNothing);

    await go(tester, '/attendance/$id/review');
    expect(find.text('Already finalized'), findsOneWidget);
  });

  testWidgets('change one session: validation, honest confirmation', (tester) async {
    await signIn(tester, 'Teacher');
    await go(tester, '/life/classes/cs302-3a/edit?session=${nextTuesdayId()}');
    expect(find.textContaining('This session only'), findsOneWidget);

    final room = find.byType(TextField).first;
    await tester.enterText(room, ' ');
    await tester.pump();
    expect(find.text('Enter a room.'), findsOneWidget);
    expect(
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save Changes')).onPressed,
        isNull);

    await tester.enterText(room, 'Room 405');
    await tester.pump();
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Students were not notified'), findsOneWidget);
    expect(find.byType(EditSessionScreen, skipOffstage: false), findsNothing); // closed
  });

  testWidgets("a teacher can't open another teacher's class", (tester) async {
    await signIn(tester, 'Teacher');
    await go(tester, '/life/classes/cs305-3a'); // Ana Reyes's class
    expect(find.text("You can't manage this class."), findsOneWidget);
  });
}
