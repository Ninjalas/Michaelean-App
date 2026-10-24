// The nav bar's pill slides to the tapped tab, and that tab's icon gives a
// tiny bounce. Instant with the phone's "reduce motion" setting.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/widgets/floating_nav_bar.dart';

const items = [
  NavItem('Home', Icons.home_outlined, Icons.home),
  NavItem('Life', Icons.school_outlined, Icons.school),
  NavItem('Profile', Icons.person_outline, Icons.person),
];

Widget bar(int selected) => MaterialApp(
      home: Scaffold(
        bottomNavigationBar:
            FloatingNavBar(items: items, selectedIndex: selected, onSelected: (_) {}),
      ),
    );

final pill = find.descendant(of: find.byType(AnimatedAlign), matching: find.byType(DecoratedBox));

double pillCenter(WidgetTester tester) => tester.getCenter(pill).dx;

double iconScale(WidgetTester tester, IconData icon) => tester
    .widget<ScaleTransition>(
        find.ancestor(of: find.byIcon(icon), matching: find.byType(ScaleTransition)))
    .scale
    .value;

void main() {
  testWidgets('the pill slides to the new tab and its icon bounces', (tester) async {
    await tester.pumpWidget(bar(0));
    final home = pillCenter(tester);
    expect(home, closeTo(tester.getCenter(find.text('Home')).dx, 1));
    expect(iconScale(tester, Icons.home), 1); // no bounce on the first build

    await tester.pumpWidget(bar(2));
    await tester.pump(const Duration(milliseconds: 100));
    final profile = tester.getCenter(find.text('Profile')).dx;
    // Midway: the pill is between the tabs, the icon is larger than normal.
    expect(pillCenter(tester), inExclusiveRange(home, profile));
    expect(iconScale(tester, Icons.person), greaterThan(1));

    await tester.pumpAndSettle();
    expect(pillCenter(tester), closeTo(profile, 1));
    expect(iconScale(tester, Icons.person), 1);
  });

  testWidgets('with reduce motion, the pill and icon change at once', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(bar(0));
    await tester.pumpWidget(bar(2));
    await tester.pump();
    expect(pillCenter(tester), closeTo(tester.getCenter(find.text('Profile')).dx, 1));
    expect(iconScale(tester, Icons.person), 1);
  });
}
