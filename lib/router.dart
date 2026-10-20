import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'models/user_profile.dart';
import 'screens/shared/app_shell.dart';
import 'screens/shared/coming_soon_screen.dart';
import 'screens/shared/notifications_sheet.dart';
import 'screens/shared/placeholder_screen.dart';
import 'screens/shared/post_detail_screen.dart';
import 'screens/shared/preview_screen.dart';
import 'screens/student/student_home_screen.dart';
import 'services/home_service.dart';
import 'services/session.dart';
import 'services/user_service.dart';
import 'widgets/app_sheet.dart';

/// All app routes. With no previewed user, everything redirects to /preview;
/// once a role is picked, the app opens on Home (spec §1).
GoRouter createRouter(
    Session session, UserService userService, HomeService homeService) {
  final rootKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootKey,
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
              builder: (context, state) => session.user?.role == UserRole.teacher
                  ? const PlaceholderScreen(title: 'Home', comingIn: 'Phase 2b')
                  : StudentHomeScreen(homeService: homeService),
              routes: [
                GoRoute(
                  path: 'post/:id',
                  builder: (context, state) => PostDetailScreen(
                    postId: state.pathParameters['id']!,
                    homeService: homeService,
                  ),
                ),
                GoRoute(
                  path: 'notifications',
                  parentNavigatorKey: rootKey, // pop-up covers the nav bar too
                  pageBuilder: (context, state) => AppSheetPage(
                    key: state.pageKey,
                    title: 'Notifications',
                    child: NotificationsSheet(homeService: homeService),
                  ),
                ),
                GoRoute(
                  path: 'soon',
                  builder: (context, state) => ComingSoonScreen(
                    title: state.uri.queryParameters['what'] ?? 'Coming soon',
                  ),
                ),
              ],
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
