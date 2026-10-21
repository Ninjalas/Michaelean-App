import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

Future<void> openProfile(WidgetTester tester, {String role = 'Student'}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MichaeleanApp(
    userService: MockUserService(),
    homeService: MockHomeService(delay: Duration.zero),
    campusService: MockCampusService(delay: Duration.zero),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text(role));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign in with Microsoft (preview)'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Profile'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows identity, masked ID, stats, tags, and event history; no QR', (tester) async {
    await openProfile(tester);

    expect(find.text('Nicolas Santos'), findsOneWidget);
    expect(find.text('ID 2023-****-21'), findsOneWidget);
    // Counted from records: 3 history entries, 2 organizations.
    expect(find.text('3 Attended  ·  2 Orgs', findRichText: true), findsOneWidget);
    for (final tag in [
      "Saint Michael's College of Laguna",
      'SBMIT',
      'Department of Computer Studies',
      'Computer Science Society',
      'SMCL Chorale',
    ]) {
      expect(find.text(tag), findsOneWidget);
    }
    expect(find.byType(QrImageView), findsNothing); // the QR lives on long-press now

    await tester.scrollUntilVisible(find.textContaining('· Volunteer'), 200);
    expect(find.text('Event History'), findsOneWidget);
    expect(find.textContaining('· Volunteer'), findsOneWidget); // role from record
    expect(find.text('Participated'), findsOneWidget); // status pill
  });

  testWidgets('teacher profile: Classes I Teach and only recorded hosting counts',
      (tester) async {
    await openProfile(tester, role: 'Teacher');
    expect(find.text('ID 2015-****-93'), findsOneWidget);
    // 3 distinct classes; 1 event recorded as host (the organizer one doesn't count).
    expect(find.text('3 Classes  ·  1 Hosted', findRichText: true), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Classes I Teach'), 200);
    expect(find.text('CS 301 · Data Structures'), findsOneWidget); // listed once
  });

  testWidgets('Edit Profile: Save only after a change; saves to this preview only',
      (tester) async {
    await openProfile(tester);
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();

    FilledButton save() =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'));
    expect(save().onPressed, isNull); // nothing changed yet
    expect(find.byType(TextField), findsOneWidget); // only About is editable
    expect(find.text('Set by the school'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Builds the Michaelean app.');
    await tester.pump();
    expect(save().onPressed, isNotNull);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Builds the Michaelean app.'), findsOneWidget); // back on Profile
    expect(find.textContaining('preview only'), findsOneWidget); // honest confirmation
  });

  testWidgets('settings opens, Back closes it; Log Out ends the preview', (tester) async {
    await openProfile(tester, role: 'Teacher');
    expect(find.text('Mark Villanueva'), findsOneWidget);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    for (final item in [
      'Personal Information',
      'Account & Security',
      'Notifications',
      'Help & Support',
      'About Michaelean',
      'Preview tools',
      'Log Out',
    ]) {
      expect(find.text(item), findsOneWidget);
    }
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Log Out'), findsNothing);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in with Microsoft (preview)'), findsOneWidget);
  });

  testWidgets('switching role in Settings refreshes every tab, not just Profile',
      (tester) async {
    await openProfile(tester); // as the student
    // Visit Home and Student Life first, so they have loaded the student's data.
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.textContaining(', Nicolas'), findsOneWidget);
    await tester.tap(find.text('Student Life'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Teacher'));
    await tester.pumpAndSettle();

    expect(find.text('Mark Villanueva'), findsOneWidget); // Profile
    await tester.tap(find.text('Michaelean Life'));
    await tester.pumpAndSettle();
    expect(find.text('Teaching & Campus'), findsOneWidget);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.textContaining(', Mark'), findsOneWidget);
    expect(find.text('Classes today'), findsOneWidget); // teacher stats, not stale student ones
  });
}
