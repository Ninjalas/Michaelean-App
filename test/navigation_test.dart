import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';

MichaeleanApp testApp() => MichaeleanApp(
      userService: MockUserService(),
      homeService: MockHomeService(delay: Duration.zero),
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
    expect(find.text('Skip'), findsNothing); // logging out doesn't replay the intro
  });

  testWidgets('Skip leaves the opening intro right away', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pump(const Duration(milliseconds: 300)); // intro still playing
    expect(find.text('Sign in with Microsoft (preview)'), findsNothing);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in with Microsoft (preview)'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
  });
}
