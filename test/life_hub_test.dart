import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';

Future<void> openHub(WidgetTester tester, String role, String tab) async {
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
  await tester.tap(find.text(tab));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Student Life lists Events, Class, Organizations, Clearance', (tester) async {
    await openHub(tester, 'Student', 'Student Life');

    expect(find.text('Your campus, beyond the classroom.'), findsOneWidget);
    for (final f in ['Events', 'Class', 'Organizations', 'Clearance']) {
      expect(find.text(f), findsOneWidget);
    }

    await tester.tap(find.text('Organizations'));
    await tester.pumpAndSettle();
    expect(find.textContaining("hasn't been built yet"), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Your Student Life'), findsOneWidget);
  });

  testWidgets('Michaelean Life disables features the teacher is not authorized for',
      (tester) async {
    await openHub(tester, 'Teacher', 'Michaelean Life');

    expect(find.text('Teaching & Campus'), findsOneWidget);
    // Mock teacher can manage classes and events, but has no clearance area.
    expect(find.text("You aren't assigned to a clearance area."), findsOneWidget);

    await tester.tap(find.text('Clearance'));
    await tester.pumpAndSettle();
    expect(find.text('Teaching & Campus'), findsOneWidget); // didn't navigate

    await tester.tap(find.text('Class Management'));
    await tester.pumpAndSettle();
    expect(find.textContaining("hasn't been built yet"), findsOneWidget);
  });
}
