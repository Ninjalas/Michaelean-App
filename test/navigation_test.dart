import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/screens/shared/opening_screen.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';

MichaeleanApp testApp() => MichaeleanApp(
      userService: MockUserService(),
      homeService: MockHomeService(delay: Duration.zero),
    campusService: MockCampusService(delay: Duration.zero),
    );

void main() {
  testWidgets('student preview opens Home with student tabs', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
    // The opening intro plays to the end and moves on to sign-in by itself.
    expect(find.text('Sign in with Microsoft (preview)'), findsOneWidget);
    expect(find.textContaining('Preview only'), findsOneWidget); // never looks like real sign-in

    await tester.tap(find.text('Sign in with Microsoft (preview)'));
    await tester.pumpAndSettle();

    expect(find.textContaining(', Nicolas'), findsOneWidget); // landed on Home
    expect(find.text('Student Life'), findsOneWidget);
    expect(find.text('Michaelean Life'), findsNothing);
  });

  testWidgets('teacher preview shows Michaelean Life tab; switching works',
      (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Teacher'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in with Microsoft (preview)'));
    await tester.pumpAndSettle();
    expect(find.textContaining(', Mark'), findsOneWidget); // teacher Home
    expect(find.text('Michaelean Life'), findsOneWidget);
    expect(find.text('Student Life'), findsNothing);

    await tester.tap(find.text('Michaelean Life'));
    await tester.pumpAndSettle();
    expect(find.text('Teaching & Campus'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in with Microsoft (preview)'), findsOneWidget);
    expect(find.byType(OpeningScreen), findsNothing); // logging out doesn't replay the intro
  });

  testWidgets('the intro has no Skip button and moves on by itself', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pump(const Duration(milliseconds: 300)); // intro still playing
    expect(find.byType(OpeningScreen), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    expect(find.text('Sign in with Microsoft (preview)'), findsNothing);

    await tester.pumpAndSettle(); // about 2.4 s later
    expect(find.text('Sign in with Microsoft (preview)'), findsOneWidget);
  });

  testWidgets('reopening at a saved address still plays the intro first', (tester) async {
    // A browser reload keeps the last address, like /#/home.
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/home';
    addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);

    await tester.pumpWidget(testApp());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(OpeningScreen), findsOneWidget); // intro is showing

    await tester.pumpAndSettle();
    expect(find.text('Sign in with Microsoft (preview)'), findsOneWidget);
  });
}
