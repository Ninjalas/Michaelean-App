import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/dates.dart';

/// Luma-style date header: "24 October" in ink, " / Friday" in muted gray
/// (spec §2.1).
class TwoToneDate extends StatelessWidget {
  final DateTime date;
  final TextStyle? style; // defaults to the section-title style

  const TwoToneDate(this.date, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: style ?? Theme.of(context).textTheme.titleLarge,
        children: [
          TextSpan(text: formatDayMonth(date)),
          TextSpan(text: ' / ${weekdayName(date)}', style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}
