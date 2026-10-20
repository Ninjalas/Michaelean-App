import 'package:go_router/go_router.dart';

import 'models/user_profile.dart';
import 'screens/shared/app_shell.dart';
import 'screens/shared/placeholder_screen.dart';
import 'screens/shared/preview_screen.dart';
import 'services/session.dart';
import 'services/user_service.dart';

/// All app routes. With no previewed user, everything redirects to /preview;
/// once a role is picked, the app opens on Home (spec §1).
GoRouter createRouter(Session session, UserService userService) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: session,
    redirect: (context, state) {
      final atPreview = state.matchedLocation == '/preview';
      if (session.user == null) return atPreview ? null : '/preview';
      if (atPreview) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/preview',
        builder: (context, state) => PreviewScreen(userService: userService),
      ),
      // indexedStack keeps each tab alive, so its scroll position and
      // inner pages are preserved when switching tabs.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Home', comingIn: 'Phase 2'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/life',
              builder: (context, state) => PlaceholderScreen(
                title: session.user?.role == UserRole.teacher
                    ? 'Michaelean Life'
                    : 'Student Life',
                comingIn: 'Phase 3',
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Profile', comingIn: 'Phase 4'),
            ),
          ]),
        ],
      ),
    ],
  );
}
