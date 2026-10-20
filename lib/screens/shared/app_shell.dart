import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_profile.dart';
import '../../services/session.dart';
import '../../widgets/floating_nav_bar.dart';

/// The frame around the three tabs. Same structure for both roles;
/// only the middle tab's name changes (spec §1).
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final role = SessionScope.of(context).user?.role ?? UserRole.student;
    return Scaffold(
      extendBody: true, // content scrolls under the floating nav bar
      body: navigationShell,
      bottomNavigationBar: FloatingNavBar(
        selectedIndex: navigationShell.currentIndex,
        onSelected: (i) => navigationShell.goBranch(
          i,
          // Tapping the current tab again returns it to its first page.
          initialLocation: i == navigationShell.currentIndex,
        ),
        items: [
          const NavItem('Home', Icons.home_outlined, Icons.home_rounded),
          role == UserRole.student
              ? const NavItem('Student Life', Icons.school_outlined, Icons.school_rounded)
              : const NavItem('Michaelean Life', Icons.auto_stories_outlined,
                  Icons.auto_stories_rounded),
          const NavItem('Profile', Icons.person_outline_rounded, Icons.person_rounded),
        ],
      ),
    );
  }
}
