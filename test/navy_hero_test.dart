// The navy hero header (spec §2.1, direction B): navy from the very top,
// behind the status bar; a card can hang over its bottom edge; text is white.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/theme/app_theme.dart';
import 'package:michaelean_app/widgets/navy_hero.dart';

const statusBar = 40.0;

Widget host({Widget? overlap, double textScale = 1}) => MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: const MediaQueryData(size: Size(320, 640), padding: EdgeInsets.only(top: statusBar))
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              NavyHero(
                overlap: overlap,
                child: const Text('Good morning, Nicolas', key: Key('title')),
              ),
              const Text('Below the hero'),
            ],
          ),
        ),
      ),
    );

final navy = find.byWidgetPredicate((w) => w is ColoredBox && w.color == AppColors.navy);

void main() {
  testWidgets('navy reaches behind the status bar; content starts below it', (tester) async {
    await tester.pumpWidget(host());
    expect(tester.getTopLeft(navy).dy, 0);
    expect(tester.getTopLeft(find.byKey(const Key('title'))).dy, greaterThan(statusBar));
    expect(find.byKey(const ValueKey('navy-hero-glow')), findsOneWidget);
    // Text inside is white without each screen having to say so.
    final style = DefaultTextStyle.of(tester.element(find.byKey(const Key('title')))).style;
    expect(style.color, AppColors.white);
    // The page continues below the navy.
    expect(tester.getTopLeft(find.text('Below the hero')).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(navy).dy));
  });

  testWidgets('an overlap card hangs 36 px below the navy', (tester) async {
    await tester.pumpWidget(host(overlap: const SizedBox(height: 80, key: Key('card'))));
    final cardBottom = tester.getBottomLeft(find.byKey(const Key('card'))).dy;
    expect(cardBottom - tester.getBottomLeft(navy).dy, 36);
  });

  testWidgets('large text on a small phone does not overflow', (tester) async {
    await tester.pumpWidget(host(
      textScale: 2,
      overlap: const Text('A card with a long line of text that has to wrap nicely'),
    ));
    expect(tester.takeException(), isNull);
  });
}
