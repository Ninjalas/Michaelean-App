import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/screens/shared/notifications_sheet.dart';
import 'package:michaelean_app/widgets/floating_nav_bar.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> openHome(WidgetTester tester,
    {String role = 'Student', bool fail = false, DateTime Function()? clock}) async {
  tester.view.physicalSize = const Size(390, 844); // phone-sized
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MichaeleanApp(
    userService: MockUserService(),
    homeService: MockHomeService(delay: Duration.zero, fail: fail, clock: clock),
    campusService: MockCampusService(delay: Duration.zero),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text(role));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign in with Microsoft (preview)'));
  await tester.pumpAndSettle();
}

/// The bell; its tooltip also says how many are unread.
final bell = find.byTooltip(RegExp('^Notifications'));

Future<void> openStudentHome(WidgetTester tester, {bool fail = false}) =>
    openHome(tester, fail: fail);

void main() {
  testWidgets('bell opens notifications; X closes it', (tester) async {
    await openStudentHome(tester);

    await tester.tap(bell);
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsNothing);
  });

  testWidgets('system Back closes the notifications pop-up', (tester) async {
    await openStudentHome(tester);
    await tester.tap(bell);
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute(); // Android / browser Back
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsNothing);
    expect(find.textContaining(', Nicolas'), findsOneWidget);
  });

  testWidgets('a notification opens its post; Back returns Home', (tester) async {
    await openStudentHome(tester);

    await tester.tap(bell);
    await tester.pumpAndSettle();
    await tester.tap(find.text('New announcement: Midterm examination schedule posted'));
    await tester.pumpAndSettle();

    expect(find.textContaining('not an official announcement'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.textContaining(', Nicolas'), findsOneWidget);
  });

  testWidgets('the bell dot shows only while something is unread', (tester) async {
    await openStudentHome(tester); // a fresh device (flutter_test_config.dart)
    // Today's three start unread; yesterday's recap was already read.
    expect(find.byTooltip('Notifications, 3 unread'), findsOneWidget);

    // Opening one marks it read.
    await tester.tap(bell);
    await tester.pumpAndSettle();
    await tester.tap(find.text('New announcement: Midterm examination schedule posted'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Notifications, 2 unread'), findsOneWidget);

    // Still read after the app is closed and opened again.
    await tester.pumpWidget(const SizedBox());
    await openStudentHome(tester);
    expect(find.byTooltip('Notifications, 2 unread'), findsOneWidget);

    // Mark all as read clears the dot.
    await tester.tap(bell);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark all as read'));
    await tester.pumpAndSettle();
    expect(find.text('Mark all as read'), findsNothing);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Notifications'), findsOneWidget);
    expect(find.byTooltip(RegExp('unread')), findsNothing);
  });

  testWidgets('stats row is always visible; a stat opens its detail', (tester) async {
    await openStudentHome(tester);
    for (final label in [
      'Class attendance',
      'Event attendance',
      'Events completed',
      'Cleared',
    ]) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('Events completed'));
    await tester.pumpAndSettle();
    expect(find.text('Event History'), findsOneWidget); // event history on Profile
  });

  testWidgets('student Up next shows the class teacher, no attendance button', (tester) async {
    await openStudentHome(tester);
    expect(find.text('UP NEXT'), findsOneWidget);
    // Which class is next depends on the time of day; each has a teacher.
    expect(
      find.byWidgetPredicate((w) =>
          w is Text &&
          const {'Ana Reyes', 'Mark Villanueva', 'Jose Cruz', 'Paolo Garcia', 'Liza Ramos'}
              .contains(w.data)),
      findsOneWidget,
    );
    expect(find.text('Start attendance'), findsNothing);
  });

  testWidgets("teacher Home: Start attendance and today's classes", (tester) async {
    await openHome(tester, role: 'Teacher');
    expect(find.text('Classes today'), findsOneWidget);
    expect(find.text('Start attendance'), findsOneWidget); // has manageAssignedClasses

    await tester.scrollUntilVisible(find.text("Today's Classes"), 200);
    expect(find.text("Today's Classes"), findsOneWidget);
  });

  testWidgets('notifications are grouped into Today and Earlier', (tester) async {
    // Noon today, so "1 hour ago" is today even right after midnight.
    final now = DateTime.now();
    await openHome(tester, clock: () => DateTime(now.year, now.month, now.day, 12));
    await tester.tap(bell);
    await tester.pumpAndSettle();
    Finder inSheet(String text) =>
        find.descendant(of: find.byType(NotificationsSheet), matching: find.text(text));
    expect(inSheet('Today'), findsOneWidget);
    expect(inSheet('Earlier'), findsOneWidget); // the 1-day-old recap
  });

  testWidgets('long-press Student Life opens the QR sheet; Back closes it', (tester) async {
    await openStudentHome(tester);
    await tester.longPress(find.text('Student Life'));
    await tester.pumpAndSettle();
    expect(find.text('Your QR code'), findsOneWidget);
    expect(find.text('Show this code to your teacher.'), findsOneWidget);
    expect(find.textContaining("doesn't verify"), findsOneWidget); // never a fake check

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Your QR code'), findsNothing);
    expect(find.textContaining(', Nicolas'), findsOneWidget); // still on Home
  });

  testWidgets('the quick-QR tip shows only the first time', (tester) async {
    SharedPreferences.setMockInitialValues({}); // a fresh device
    await openStudentHome(tester);
    final tip = find.text('Tip: hold Student Life to show your QR');
    expect(tip, findsOneWidget);
    // Visible above the nav bar, not hidden behind it.
    expect(tester.getBottomLeft(tip).dy,
        lessThan(tester.getTopLeft(find.byType(FloatingNavBar)).dy));

    await tester.pumpWidget(const SizedBox()); // close the app
    await openStudentHome(tester); // and open it again
    expect(find.textContaining('Tip: hold'), findsNothing);
  });

  testWidgets('load failure shows Retry, never fake content', (tester) async {
    await openStudentHome(tester, fail: true);
    expect(find.text("Couldn't load your feed."), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Pending Tasks'), findsNothing);
  });
}
