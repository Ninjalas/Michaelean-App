import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/screens/shared/notifications_sheet.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';

Future<void> openSettingsItem(WidgetTester tester, String item) async {
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
  await tester.tap(find.text('Open preview')); // Student is preselected
  await tester.pumpAndSettle();
  await tester.tap(find.text('Profile'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Personal Information is read-only and keeps the ID masked', (tester) async {
    await openSettingsItem(tester, 'Personal Information');
    expect(find.text('2023-****-21'), findsOneWidget);
    expect(find.text('nicolas.santos@smcl.example'), findsOneWidget);
    expect(find.byType(TextField), findsNothing); // nothing to edit
    final note = find.textContaining("can't be changed in the app");
    await tester.scrollUntilVisible(note, 200, scrollable: find.byType(Scrollable).first);
    expect(note, findsOneWidget);
  });

  testWidgets('Account & Security says honestly that nothing is connected', (tester) async {
    await openSettingsItem(tester, 'Account & Security');
    expect(find.text('Not connected in this preview'), findsOneWidget);
    await tester.tap(find.text('Show my QR'));
    await tester.pumpAndSettle();
    expect(find.text('Your QR code'), findsWidgets);
  });

  testWidgets('switching a type off hides it from the bell; urgent ones stay', (tester) async {
    await openSettingsItem(tester, 'Notifications');
    await tester.tap(find.text('Organizations'));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Organizations')).value,
        isFalse);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(RegExp('^Notifications')));
    await tester.pumpAndSettle();
    // The urgent venue-change notice still shows; the seminar recap is hidden.
    // (Only inside the pop-up: Home's feed behind it has posts by those names.)
    Finder inBell(String t) =>
        find.descendant(of: find.byType(NotificationsSheet), matching: find.textContaining(t));
    expect(inBell('Venue change'), findsOneWidget);
    expect(inBell('Recap:'), findsNothing);
    // The note is at the end of a longer list now.
    await tester.scrollUntilVisible(find.text('1 hidden by your notification settings.'), 200,
        scrollable: find.descendant(
            of: find.byType(NotificationsSheet), matching: find.byType(Scrollable)));
    expect(find.text('1 hidden by your notification settings.'), findsOneWidget);
  });

  testWidgets('Help & Support answers questions and lists offices', (tester) async {
    await openSettingsItem(tester, 'Help & Support');
    await tester.tap(find.text('Does registering for an event count as attending?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Registering saves your spot'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('IT Help Desk'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('IT Help Desk'), findsOneWidget);
  });

  testWidgets('About shows the version and the open-source licenses', (tester) async {
    await openSettingsItem(tester, 'About Michaelean');
    expect(find.text('Version 0.1.0 · Prototype'), findsOneWidget);
    // Scroll past the row so it's clear of the floating nav bar.
    await tester.scrollUntilVisible(find.textContaining('Built with Flutter'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Open-source licenses'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });
}
