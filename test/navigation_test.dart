import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/services/user_service.dart';

void main() {
  testWidgets('student preview opens Home with student tabs', (tester) async {
    await tester.pumpWidget(MichaeleanApp(userService: MockUserService()));
    await tester.pumpAndSettle();
    expect(find.text('Preview as Student'), findsOneWidget);

    await tester.tap(find.text('Preview as Student'));
    await tester.pumpAndSettle();

    expect(find.text('Coming in Phase 2'), findsOneWidget); // landed on Home
    expect(find.text('Student Life'), findsOneWidget);
    expect(find.text('Michaelean Life'), findsNothing);
  });

  testWidgets('teacher preview shows Michaelean Life tab; switching works',
      (tester) async {
    await tester.pumpWidget(MichaeleanApp(userService: MockUserService()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Preview as Teacher'));
    await tester.pumpAndSettle();
    expect(find.text('Michaelean Life'), findsOneWidget);
    expect(find.text('Student Life'), findsNothing);

    await tester.tap(find.text('Michaelean Life'));
    await tester.pumpAndSettle();
    expect(find.text('Coming in Phase 3'), findsOneWidget);

    await tester.tap(find.text('Switch preview role'));
    await tester.pumpAndSettle();
    expect(find.text('Preview as Student'), findsOneWidget);
  });
}
