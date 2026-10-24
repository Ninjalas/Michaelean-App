import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/screens/teacher/event_checkin_screen.dart';
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
  testWidgets('Event History opens the event page with your record', (tester) async {
    await signIn(tester, 'Student');
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    final row = find.text('Machine learning with the Iris dataset');
    await tester.scrollUntilVisible(row, 300, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(row); // to the top, clear of the nav bar
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text('Your record: Attended · Participant'), findsOneWidget);
    expect(find.text('Venue'), findsOneWidget);
    expect(find.text('Register'), findsNothing); // it's over; nothing to register for

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Event History'), findsOneWidget); // back on Profile
  });

  testWidgets('Home event stats are counted from records', (tester) async {
    await signIn(tester, 'Student');
    // 3 recorded events; 3 of the 4 past events registered or recorded.
    expect(find.text('3'), findsWidgets);
    expect(find.text('75%'), findsOneWidget);
  });

  testWidgets('Share copies the event details', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,
        (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await signIn(tester, 'Student');
    await go(tester, '/life/events/ev1');
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(find.text('Event details copied.'), findsOneWidget);
    expect(copied, contains('CSS General Assembly'));
    expect(copied, contains('Milagros Limaco Hall'));
  });

  testWidgets('teacher check-in: scan, finalize, honest message', (tester) async {
    await signIn(tester, 'Teacher');
    await go(tester, '/life/events/ev2');
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take attendance'));
    await tester.pumpAndSettle();
    expect(find.text('MOCK SCANNER · no camera is used'), findsOneWidget);
    expect(find.text('Present 0 · Registered 5'), findsOneWidget);

    await tester.tap(find.text('Open anyway (preview tool)')); // the event is days away
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simulate scan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Present'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Present 1 · Registered 5'), findsOneWidget);

    await tester.tap(find.text('Finalize'));
    await tester.pumpAndSettle();
    expect(find.text('Finalize attendance?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Finalize'));
    await tester.pumpAndSettle();
    expect(find.text('Attendance finalized in this preview only. Not an official record.'),
        findsOneWidget);
    expect(find.byType(EventCheckInScreen, skipOffstage: false), findsNothing);
  });
}
