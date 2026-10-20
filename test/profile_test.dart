import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';
import 'package:michaelean_app/widgets/profile_coin.dart';
import 'package:qr_flutter/qr_flutter.dart';

Future<void> openProfile(WidgetTester tester, {String role = 'Student'}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MichaeleanApp(
    userService: MockUserService(),
    homeService: MockHomeService(delay: Duration.zero),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Preview as $role'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Profile'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows identity, masked ID, tags, and event history', (tester) async {
    await openProfile(tester);

    expect(find.text('Nicolas Santos'), findsOneWidget);
    expect(find.text('ID ••••-••-4821'), findsOneWidget);
    for (final tag in [
      "Saint Michael's College of Laguna",
      'SBMIT',
      'Department of Computer Studies',
      'Computer Science Society',
    ]) {
      expect(find.text(tag), findsOneWidget);
    }
    await tester.scrollUntilVisible(find.textContaining('· Volunteer'), 200);
    expect(find.textContaining('· Volunteer'), findsOneWidget); // role from record
    expect(find.text('Participated'), findsOneWidget); // status pill
    expect(find.textContaining('· Participant'), findsWidgets);
  });

  testWidgets('coin flips to QR and back; QR holds only the mock token', (tester) async {
    await openProfile(tester);
    expect(find.byType(QrImageView), findsNothing);
    expect(tester.widget<ProfileCoin>(find.byType(ProfileCoin)).qrData, 'MOCK-7F3K9Q');

    await tester.tap(find.byType(ProfileCoin));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);

    await tester.tap(find.byType(ProfileCoin));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsNothing);
  });

  testWidgets('a second tap mid-flip is ignored', (tester) async {
    await openProfile(tester);

    await tester.tap(find.byType(ProfileCoin));
    await tester.pump(const Duration(milliseconds: 150)); // still flipping
    await tester.tap(find.byType(ProfileCoin));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget); // stayed on the QR side
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
    expect(find.text('Preview as Student'), findsOneWidget);
  });
}
