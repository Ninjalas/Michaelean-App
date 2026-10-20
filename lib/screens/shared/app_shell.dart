import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_profile.dart';
import '../../services/hint_store.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/floating_nav_bar.dart';

/// The frame around the three tabs. Same structure for both roles;
/// only the middle tab's name changes (spec §1.2). Long-pressing the middle
/// tab opens the user's QR sheet (spec §1.3).
class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _showHint = false;
  Timer? _hintTimer;

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
    super.dispose();
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
    return Scaffold(
      extendBody: true, // content scrolls under the floating nav bar
      body: Stack(
        children: [
          shell,
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
        onSelected: (i) => shell.goBranch(
          i,
          // Tapping the current tab again returns it to its first page.
          initialLocation: i == shell.currentIndex,
        ),
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
