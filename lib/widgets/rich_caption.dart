import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Post text as the school writes it on Facebook: **bold** parts in the
/// app's bold font (Facebook's styled bold letters were converted to plain
/// ones, which every phone can show), #hashtags in navy, and links in navy
/// too but not tappable in this preview.
class RichCaption extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const RichCaption(this.text, {super.key, this.style});

  static final _marks = RegExp(r'\*\*(.+?)\*\*|https?://\S+|#\w+');

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    var at = 0;
    for (final m in _marks.allMatches(text)) {
      if (m.start > at) spans.add(TextSpan(text: text.substring(at, m.start)));
      spans.add(m.group(1) != null
          ? TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w700))
          : TextSpan(
              text: m.group(0),
              style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600)));
      at = m.end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return Text.rich(TextSpan(style: style, children: spans));
  }
}
