import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/mock/mock_people.dart';
import 'package:michaelean_app/models/user_profile.dart';
import 'package:michaelean_app/screens/shared/change_password_screen.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/supabase_user_service.dart';
import 'package:michaelean_app/services/user_service.dart';

/// A row shaped like the Supabase `profiles` table (a made-up student).
const _row = {
  'id': '6f1c2d3e-0000-4000-8000-000000000001',
  'role': 'student',
  'email': 'Rufino.Diolata@smcl.edu.ph',
  'first_name': 'Rufino',
  'last_name': 'Diolata',
  'suffix': 'III',
  'program': 'BSCS',
  'year_level': 3,
  'masked_id': '2024-****-37',
  'about': null,
};

/// Stands in for Supabase: one account, password "right-password".
class _FakeAccounts extends MockUserService {
  _FakeAccounts({super.campus});
  bool signedOut = false;
  String? changedTo;

  @override
  Future<UserProfile> signIn(String email, String password) async {
    if (password != 'right-password') throw const SignInException('Wrong email or password.');
    return profileFromRow(_row, 'MOCK-TEST0001');
  }

  @override
  Future<void> signOut() async => signedOut = true;

  @override
  Future<void> changePassword(String current, String next) async {
    if (current != 'right-password') throw const SignInException('Your current password is wrong.');
    changedTo = next;
  }
}

Future<_FakeAccounts> _openApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final campus = MockCampusService(delay: Duration.zero);
  final accounts = _FakeAccounts(campus: campus);
  await tester.pumpWidget(MichaeleanApp(
    userService: accounts,
    homeService: MockHomeService(delay: Duration.zero, campus: campus),
    campusService: campus,
  ));
  await tester.pumpAndSettle();
  return accounts;
}

Future<void> _signIn(WidgetTester tester, String password) async {
  await tester.enterText(find.widgetWithText(TextField, 'School email'), 'Rufino.Diolata@smcl.edu.ph');
  await tester.enterText(find.widgetWithText(TextField, 'Password'), password);
  await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
  await tester.pumpAndSettle();
}

void main() {
  test('a profiles row becomes the app profile', () {
    final u = profileFromRow(_row, 'MOCK-TEST0001');
    expect(u.fullName, 'Rufino Diolata III');
    expect(u.designation, 'BS Computer Science · 3rd Year');
    expect(u.role, UserRole.student);
    expect(u.maskedId, '2024-****-37');
    expect(u.qrToken, 'MOCK-TEST0001');
    expect(u.tags, mockSampleStudentTags);
    expect(u.permissions, isEmpty); // identity is not permission
    expect(profileFromRow({..._row, 'program': 'ACT-IT', 'year_level': 1, 'suffix': null}, 't')
        .designation, 'Associate in Computer Technology (IT) · 1st Year');
  });

  test("Home greets by the first word of the first name", () {
    UserProfile named(String first) => profileFromRow({..._row, 'first_name': first}, 't');
    expect(named('Nicolas Emanuel').greetingName, 'Nicolas');
    expect(named('Ma. Diane').greetingName, 'Diane');
    expect(named('Rufino').greetingName, 'Rufino');
  });

  test('new password rules', () {
    expect(ChangePasswordScreen.problem('', 'abcdefgh', 'abcdefgh'), isNotNull);
    expect(ChangePasswordScreen.problem('old-pass', 'short', 'short'), contains('8'));
    expect(ChangePasswordScreen.problem('same-pass', 'same-pass', 'same-pass'), contains('different'));
    expect(ChangePasswordScreen.problem('old-pass', 'new-pass1', 'new-pass2'), contains("don't match"));
    expect(ChangePasswordScreen.problem('old-pass', 'new-pass1', 'new-pass1'), isNull);
  });

  testWidgets('wrong password shows an error and stays on sign-in', (tester) async {
    await _openApp(tester);
    await _signIn(tester, 'wrong');
    expect(find.text('Wrong email or password.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });

  testWidgets('signing in opens the app as that student; log out signs out', (tester) async {
    final accounts = await _openApp(tester);
    await _signIn(tester, 'right-password');
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsNothing); // on Home now

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Rufino'), findsWidgets);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Preview tools'), findsNothing); // no sample-account switching
    expect(find.text('Signs you out on this device'), findsOneWidget);

    await tester.tap(find.text('Account & Security'));
    await tester.pumpAndSettle();
    expect(find.text('Rufino.Diolata@smcl.edu.ph'), findsOneWidget);
    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Current password'), 'right-password');
    await tester.enterText(find.widgetWithText(TextField, 'New password'), 'my-new-pass');
    await tester.enterText(find.widgetWithText(TextField, 'Type the new password again'), 'my-new-pass');
    await tester.tap(find.widgetWithText(FilledButton, 'Change password'));
    await tester.pumpAndSettle();
    expect(accounts.changedTo, 'my-new-pass');
    expect(find.textContaining('Password changed'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();
    expect(accounts.signedOut, isTrue);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });

  testWidgets('a wrong current password is reported, nothing changes', (tester) async {
    final accounts = await _openApp(tester);
    await _signIn(tester, 'right-password');
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Account & Security'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Current password'), 'nope-nope');
    await tester.enterText(find.widgetWithText(TextField, 'New password'), 'my-new-pass');
    await tester.enterText(find.widgetWithText(TextField, 'Type the new password again'), 'my-new-pass');
    await tester.tap(find.widgetWithText(FilledButton, 'Change password'));
    await tester.pumpAndSettle();
    expect(find.text('Your current password is wrong.'), findsOneWidget);
    expect(accounts.changedTo, isNull);
  });
}
