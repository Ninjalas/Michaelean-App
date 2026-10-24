import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A column of rows that animates when the list changes (spec §2.5): a row
/// that's gone fades and folds away, and the rows below slide up; a new row
/// fades and unfolds in. Rows are matched by their keys, so give each one a
/// key that stays the same (e.g. `ValueKey(student.id)`). Nothing animates
/// on the first build, and nothing at all with the phone's reduce-motion
/// setting.
class AnimatedRows extends StatefulWidget {
  final List<Widget> children;

  /// Shown above every row but the first, e.g. a Divider.
  final Widget? separator;

  const AnimatedRows({super.key, required this.children, this.separator});

  @override
  State<AnimatedRows> createState() => _AnimatedRowsState();
}

class _Row {
  final Key key;
  Widget child;
  final AnimationController controller;
  bool leaving = false;

  _Row(this.key, this.child, this.controller);
}

class _AnimatedRowsState extends State<AnimatedRows> with TickerProviderStateMixin {
  final _rows = <_Row>[];

  AnimationController _controller({required bool shown}) =>
      AnimationController(vsync: this, value: shown ? 1 : 0);

  Key _keyOf(Widget w) {
    assert(w.key != null, 'AnimatedRows: every row needs a key');
    return w.key!;
  }

  @override
  void initState() {
    super.initState();
    _rows.addAll([
      for (final c in widget.children) _Row(_keyOf(c), c, _controller(shown: true)),
    ]);
  }

  @override
  void didUpdateWidget(AnimatedRows old) {
    super.didUpdateWidget(old);
    final duration = AppMotion.of(context, AppMotion.normal);
    final existing = {for (final r in _rows) r.key: r};
    final incoming = {for (final c in widget.children) _keyOf(c): c};

    // The new order, with rows that just left kept after the row they
    // followed, so they fold away where they were.
    final next = <_Row>[];
    for (final c in widget.children) {
      final r = existing[_keyOf(c)];
      if (r != null) {
        r.child = c;
        if (r.leaving) {
          r.leaving = false; // came back before it finished leaving
          r.controller.animateTo(1, duration: duration, curve: AppMotion.curve);
        }
        next.add(r);
      } else {
        final added = _Row(_keyOf(c), c, _controller(shown: duration == Duration.zero));
        added.controller.animateTo(1, duration: duration, curve: AppMotion.curve);
        next.add(added);
      }
    }
    for (var i = 0; i < _rows.length; i++) {
      final r = _rows[i];
      if (incoming.containsKey(r.key)) continue;
      final before = i == 0 ? null : _rows[i - 1];
      final at = before == null ? 0 : next.indexOf(before) + 1;
      if (duration == Duration.zero) {
        // Reduce motion: gone at once.
        r.leaving = true;
        _disposeLater(r);
        continue;
      }
      next.insert(at, r);
      if (!r.leaving) {
        r.leaving = true;
        r.controller
            .animateBack(0, duration: duration, curve: AppMotion.curve)
            .whenComplete(() => _remove(r));
      }
    }
    _rows
      ..clear()
      ..addAll(next);
  }

  /// Drops a row once it has folded away, unless it came back meanwhile.
  void _remove(_Row r) {
    if (!mounted || !r.leaving || !r.controller.isDismissed) return;
    setState(() => _rows.remove(r));
    _disposeLater(r);
  }

  /// After this frame, when nothing paints with the controller any more.
  void _disposeLater(_Row r) =>
      WidgetsBinding.instance.addPostFrameCallback((_) => r.controller.dispose());

  @override
  void dispose() {
    for (final r in _rows) {
      r.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _rows.where((r) => !r.leaving).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final r in _rows)
          SizeTransition(
            key: r.key,
            sizeFactor: r.controller,
            alignment: Alignment.topCenter, // fold up toward the row above
            child: FadeTransition(
              opacity: r.controller,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Above every row but the first one still shown.
                  if (widget.separator != null && (shown.isEmpty || shown.first != r))
                    widget.separator!,
                  r.child,
                ],
              ),
            ),
          ),
      ],
    );
  }
}
