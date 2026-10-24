import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_profile.dart';
import '../../services/hint_store.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/floating_nav_bar.dart';
import '../../widgets/tab_reselect.dart';

/// The frame around the three tabs. Same structure for both roles;
/// only the middle tab's name changes (spec §1.2). Long-pressing the middle
/// tab opens the user's QR sheet (spec §1.3).
class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  bool _showHint = false;
  Timer? _hintTimer;
  final _taps = [TabTap(), TabTap(), TabTap()]; // Home, Life, Profile

  /// Fades the newly shown tab in when the tab changes (spec §2.5).
  late final _tabFade = AnimationController(vsync: this, value: 1);
  late final _tabOpacity = CurvedAnimation(parent: _tabFade, curve: AppMotion.curve);

  @override
  void didUpdateWidget(AppShell old) {
    super.didUpdateWidget(old);
    if (old.navigationShell.currentIndex != widget.navigationShell.currentIndex) {
      _tabFade.duration = AppMotion.of(context, AppMotion.fast);
      _tabFade.forward(from: 0);
    }
  }

  @override
  void initState() {
    super.initState();
    HintStore.showOnce(HintStore.quickQr).then((show) {
      if (!show || !mounted) return;
      setState(() => _showHint = true);
      _hintTimer = Timer(const Duration(seconds: 8), _hideHint);
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _tabOpacity.dispose();
    _tabFade.dispose();
    for (final t in _taps) {
      t.dispose();
    }
    super.dispose();
  }

  /// Another tab: switch to it. The current tab: go back to its first page
  /// with the usual Back animation, or, already there, glide to the top.
  void _onTab(int i) {
    final shell = widget.navigationShell;
    if (i != shell.currentIndex) {
      shell.goBranch(i);
      return;
    }
    final nav = shell.route.branches[i].navigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
    } else {
      _taps[i].tap();
    }
  }

  void _hideHint() {
    if (mounted && _showHint) setState(() => _showHint = false);
  }

  void _openQr() {
    HapticFeedback.mediumImpact();
    _hideHint(); // they found it
    context.push('/qr');
  }

  @override
  Widget build(BuildContext context) {
    final role = SessionScope.of(context).user?.role ?? UserRole.student;
    final lifeLabel = role == UserRole.student ? 'Student Life' : 'Michaelean Life';
    final shell = widget.navigationShell;
    return TabReselect(
      taps: _taps,
      child: Scaffold(
        extendBody: true, // content scrolls under the floating nav bar
        body: Stack(
          children: [
            FadeTransition(
              opacity: _tabOpacity,
              child: shell,
            ),
            // Builder: read the body's padding, which (with extendBody) includes
            // the nav bar's height, so the tip sits just above the bar.
            Builder(
              builder: (context) => Positioned(
                left: AppSpacing.screen,
                right: AppSpacing.screen,
                bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.sm,
                child: AnimatedSwitcher(
                  duration: AppMotion.normal,
                  child: _showHint
                      ? _HintBubble(
                          text: 'Tip: hold $lifeLabel to show your QR',
                          onClose: _hideHint,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: FloatingNavBar(
          selectedIndex: shell.currentIndex,
          onSelected: _onTab,
          items: [
            const NavItem('Home', Icons.home_outlined, Icons.home_rounded),
            role == UserRole.student
                ? NavItem('Student Life', Icons.school_outlined, Icons.school_rounded,
                    onLongPress: _openQr, longPressHint: 'show your QR code')
                : NavItem('Michaelean Life', Icons.auto_stories_outlined,
                    Icons.auto_stories_rounded,
                    onLongPress: _openQr, longPressHint: 'show your QR code'),
            const NavItem('Profile', Icons.person_outline_rounded, Icons.person_rounded),
          ],
        ),
      ),
    );
  }
}

/// Small dark speech bubble above the nav bar, shown once (spec §1.3).
class _HintBubble extends StatelessWidget {
  final String text;
  final VoidCallback onClose;

  const _HintBubble({required this.text, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: AppColors.floatShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.touch_app_outlined, color: AppColors.white, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.white)),
            ),
            IconButton(
              tooltip: 'Dismiss tip',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, color: AppColors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
