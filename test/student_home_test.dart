import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';

Future<void> openStudentHome(WidgetTester tester, {bool fail = false}) async {
  tester.view.physicalSize = const Size(390, 844); // phone-sized
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MichaeleanApp(
    userService: MockUserService(),
    homeService: MockHomeService(delay: Duration.zero, fail: fail),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Preview as Student'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('bell opens notifications; X closes it', (tester) async {
    await openStudentHome(tester);

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsNothing);
  });

  testWidgets('system Back closes the notifications pop-up', (tester) async {
    await openStudentHome(tester);
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute(); // Android / browser Back
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsNothing);
    expect(find.textContaining(', Nicolas'), findsOneWidget);
  });

  testWidgets('a notification opens its post; Back returns Home', (tester) async {
    await openStudentHome(tester);

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New announcement: Midterm examination schedule posted'));
    await tester.pumpAndSettle();

    expect(find.textContaining('not an official announcement'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.textContaining(', Nicolas'), findsOneWidget);
  });

  testWidgets('overview expands to show the four metrics', (tester) async {
    await openStudentHome(tester);
    expect(find.text('Class Attendance'), findsNothing);

    await tester.tap(find.text('Attendance Overview'));
    await tester.pumpAndSettle();
    for (final label in [
      'Class Attendance',
      'Event Attendance',
      'Events Completed',
      'Event Requirements',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('load failure shows Retry, never fake content', (tester) async {
    await openStudentHome(tester, fail: true);
    expect(find.text("Couldn't load your feed."), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Pending Tasks'), findsNothing);
  });
}
