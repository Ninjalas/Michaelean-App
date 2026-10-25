// Grades, step 2 (spec §7.6): the Grades page. Opens on this semester,
// switches to past ones, shows "—" for grades not out yet, red and Failed
// below 75, and the overall average.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';
import 'package:michaelean_app/theme/app_theme.dart';

Future<void> openGrades(WidgetTester tester, String role) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final campus = MockCampusService(delay: Duration.zero, clock: () => DateTime(2026, 10, 25, 9));
  await tester.pumpWidget(MichaeleanApp(
    userService: MockUserService(campus: campus),
    homeService: MockHomeService(delay: Duration.zero, campus: campus),
    campusService: campus,
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text(role));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign in with Microsoft (preview)'));
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/life/grades');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens on this semester: midterms out, finals mostly "—"', (tester) async {
    await openGrades(tester, 'Student');
    // Short semester names, so all three fit.
    for (final sem in ['1st Sem 26–27', '2nd Sem 25–26', '1st Sem 25–26']) {
      expect(find.text(sem), findsOneWidget);
    }
    for (final h in ['Course', 'Units', 'Midterm', 'Final', 'Average']) {
      expect(find.text(h), findsOneWidget);
    }
    expect(find.text('CS 302'), findsOneWidget);
    // The Course heading lines up with the course codes under it.
    expect(tester.getTopLeft(find.text('Course')).dx, tester.getTopLeft(find.text('CS 302')).dx);
    expect(find.text('—'), findsNWidgets(8)); // 4 finals + 4 averages not out yet
    // Only GE 104 is finished (93, 95 → 94 → 1.50): the GWA counts just that course.
    expect(find.text('94.00%'), findsOneWidget); // the percentage, beside the GWA
    expect(find.text('1.50'), findsNWidgets(2)); // the card's GWA and GE 104's grade point
    expect(find.text('Based on 1 of 5 courses · 3 units'), findsOneWidget);
    expect(find.text('Failed'), findsNothing);
    expect(find.textContaining('Sample grades, not official records'), findsOneWidget);
  });

  testWidgets('a past semester: grade points, red grades, and the two fail tags', (tester) async {
    await openGrades(tester, 'Student');
    // Semesters scroll sideways (more pile up each year): scroll to it first.
    await tester.ensureVisible(find.text('1st Sem 25–26'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1st Sem 25–26'));
    await tester.pumpAndSettle();
    expect(find.text('CS 203'), findsOneWidget);
    expect(find.text('—'), findsNothing);
    expect(find.text('2.26'), findsOneWidget); // GWA from grade points: 38.50 ÷ 17
    expect(find.text('85.76%'), findsOneWidget); // in percent: 1458 ÷ 17
    expect(find.text('6 courses · 17 units'), findsOneWidget);
    // Each average shows its grade point under it: CS 201's 90 → 1.75.
    expect(find.text('1.75'), findsOneWidget);
    // CS 203 averages 71: 4.00, a conditional fail.
    expect(find.text('4.00'), findsOneWidget);
    expect(find.text('Conditional fail'), findsOneWidget);
    expect(find.text('Failed'), findsNothing);
    // CS 203's grades (72, 70, average 71) are red; passing ones aren't.
    Color? colorOf(String s) => tester.widget<Text>(find.text(s)).style?.color;
    expect(colorOf('72'), AppColors.red);
    expect(colorOf('71'), AppColors.red);
    expect(colorOf('92'), isNot(AppColors.red)); // CS 201's final
    // Screen readers hear a whole row at once.
    expect(
      find.bySemanticsLabel('CS 203, 3 units, midterm 72, final 70, average 71, '
          'grade point 4.00, conditional fail'),
      findsOneWidget,
    );
    // The semester before has a 5.00: MATH 202 averages 67, Failed.
    await tester.tap(find.text('2nd Sem 25–26'));
    await tester.pumpAndSettle();
    expect(find.text('5.00'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('Conditional fail'), findsNothing);
  });

  testWidgets('tapping the GWA explains it, by units or simple', (tester) async {
    await openGrades(tester, 'Student');
    await tester.ensureVisible(find.text('1st Sem 25–26'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1st Sem 25–26'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2.26'));
    await tester.pumpAndSettle();
    expect(find.text('How your average is counted'), findsOneWidget);
    // By units (GWA), the default: each average → its grade point × units.
    expect(find.text('90 → 1.75 × 3'), findsOneWidget); // CS 201
    expect(find.text('96 → 1.25 × 2'), findsOneWidget); // PE 102, 2 units
    expect(find.text('71 → 4.00 × 3'), findsOneWidget); // CS 203
    expect(find.text('5.25'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('38.50 ÷ 17 units'), 200,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('38.50 ÷ 17 units'), findsOneWidget);
    expect(find.text('2.26'), findsNWidgets(2)); // the page's card and the sheet
    expect(find.text('In percent: 85.76%'), findsOneWidget);
    // SMCL's scale, for reference.
    await tester.scrollUntilVisible(find.text('SMCL grading scale'), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.scrollUntilVisible(find.text('Below 70'), 200,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('Conditional Fail'), findsOneWidget);
    // Simple average: every course counts the same.
    await tester.scrollUntilVisible(find.text('Simple average'), -200,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Simple average'));
    await tester.pumpAndSettle();
    expect(find.text('90 → 1.75 × 3'), findsNothing);
    expect(find.text('90 → 1.75'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('13.25 ÷ 6 courses'), 200,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('13.25 ÷ 6 courses'), findsOneWidget);
    expect(find.text('2.21'), findsOneWidget);
    expect(find.text('In percent: 86.33%'), findsOneWidget);
    // The X closes the sheet, back to the page.
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('How your average is counted'), findsNothing);
    expect(find.text('CS 203'), findsOneWidget);
  });

  testWidgets('this semester: the sheet says which courses are not counted yet', (tester) async {
    await openGrades(tester, 'Student');
    await tester.tap(find.text('94.00%'));
    await tester.pumpAndSettle();
    expect(find.text('94 → 1.50 × 3'), findsOneWidget); // GE 104, the only finished course
    expect(find.text('4.50 ÷ 3 units'), findsOneWidget);
    expect(
      find.text("Not counted yet (a grade isn’t out): CS 302, CS 305, CS 306, PE 103."),
      findsOneWidget,
    );
  });

  testWidgets('a teacher has no grades to show', (tester) async {
    await openGrades(tester, 'Teacher');
    expect(find.text('No grades to show.'), findsOneWidget);
  });
}
