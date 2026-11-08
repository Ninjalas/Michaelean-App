import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/screens/teacher/clearance_case_screen.dart';
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
  await tester.tap(find.text('Open preview'));
  await tester.pumpAndSettle();
}

Future<void> go(WidgetTester tester, String path) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).push(path);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('student: progress, a returned item, honest resubmit', (tester) async {
    await signIn(tester, 'Student');
    await go(tester, '/life/clearance');
    expect(find.text('1st Semester Clearance'), findsWidgets);
    expect(find.textContaining('/ 7 cleared', findRichText: true), findsOneWidget);
    expect(find.text('Needs correction'), findsOneWidget);

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Returned by Library'), findsOneWidget);
    expect(find.text('Receipt photo is unreadable. Resubmit a clearer copy.'), findsOneWidget);
    await tester.tap(find.text('Resubmit for Review'));
    await tester.pumpAndSettle();
    expect(find.textContaining("it isn't cleared until the office reviews it"), findsOneWidget);
    expect(find.text('In review'), findsOneWidget);
    expect(find.text('Resubmit for Review'), findsNothing);
  });

  testWidgets('staff: scan finds the student; outcome needs a reason; honest save',
      (tester) async {
    await signIn(tester, 'Teacher');
    await go(tester, '/life/verify');
    expect(find.text('Department of Computer Studies'), findsOneWidget);
    expect(find.text('Bea Villareal'), findsOneWidget); // pending

    await tester.tap(find.text('Scan Student QR'));
    await tester.pumpAndSettle();
    expect(find.text('MOCK SCANNER · no camera is used'), findsOneWidget);
    await tester.tap(find.text('Unknown code'));
    await tester.pumpAndSettle();
    expect(find.text('No student matches this code. Nothing was recorded.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // the message goes away
    await tester.pumpAndSettle();

    // Simulate scan reads the first pending student's mock code (Bea Villareal).
    await tester.tap(find.text('Scan Student QR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simulate scan'));
    await tester.pumpAndSettle();
    expect(find.byType(ClearanceCaseScreen), findsOneWidget);
    expect(find.text('Bea Villareal'), findsOneWidget);
    expect(find.text('Laboratory equipment return'), findsOneWidget);

    final record = find.widgetWithText(FilledButton, 'Record Outcome');
    await tester.tap(find.text('Needs Correction'));
    await tester.pump();
    expect(tester.widget<FilledButton>(record).onPressed, isNull); // reason missing
    await tester.enterText(find.byType(TextField), 'Projector cable still missing.');
    await tester.pump();
    await tester.tap(record);
    await tester.pumpAndSettle();
    expect(find.text('Record Needs Correction?'), findsOneWidget);
    await tester.tap(find.text('Record'));
    await tester.pumpAndSettle();
    expect(find.text('Recorded in this preview only. Not an official clearance record.'),
        findsOneWidget);
    expect(find.byType(ClearanceCaseScreen, skipOffstage: false), findsNothing);
    expect(find.text('Bea Villareal'), findsNothing); // no longer pending
  });
}
