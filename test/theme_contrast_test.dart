// The theme's text and background pairs stay readable (WCAG AA: 4.5:1 for
// normal text). The screen audit checks tap targets and labels, not this.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/theme/app_theme.dart';

double contrast(Color a, Color b) {
  final (x, y) = (a.computeLuminance(), b.computeLuminance());
  return (x > y ? x + 0.05 : y + 0.05) / (x > y ? y + 0.05 : x + 0.05);
}

void main() {
  test('text on every surface meets 4.5:1', () {
    final pairs = {
      'ink on page': (AppColors.ink, AppColors.page),
      'muted on page': (AppColors.muted, AppColors.page),
      'muted on white': (AppColors.muted, AppColors.white),
      'trackText on track': (AppColors.trackText, AppColors.track),
      'white on navy': (AppColors.white, AppColors.navy),
      'navy on white': (AppColors.navy, AppColors.white),
      'red on white': (AppColors.red, AppColors.white),
      'red on page': (AppColors.red, AppColors.page),
      'amber on its tint': (AppColors.amber, AppColors.amberTint),
      'green on its tint': (AppColors.green, AppColors.greenTint),
      'red on its tint': (AppColors.red, AppColors.redTint),
      'navy on its tint': (AppColors.navy, AppColors.navyTint),
    };
    pairs.forEach((name, p) =>
        expect(contrast(p.$1, p.$2), greaterThanOrEqualTo(4.5), reason: name));
  });
}
