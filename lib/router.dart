import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'screens/shared/app_shell.dart';
import 'screens/shared/coming_soon_screen.dart';
import 'screens/shared/edit_profile_screen.dart';
import 'screens/shared/home_screen.dart';
import 'screens/shared/life_hub_screen.dart';
import 'screens/shared/notifications_sheet.dart';
import 'screens/shared/opening_screen.dart';
import 'screens/shared/profile_screen.dart';
import 'screens/shared/qr_sheet.dart';
import 'screens/shared/settings_sheet.dart';
import 'screens/student/class_screen.dart';
import 'screens/teacher/attendance_review_screen.dart';
import 'screens/teacher/attendance_scan_screen.dart';
import 'screens/teacher/class_detail_screen.dart';
import 'screens/teacher/classes_screen.dart';
import 'screens/teacher/edit_session_screen.dart';
import 'screens/shared/post_detail_screen.dart';
import 'screens/shared/preview_screen.dart';
import 'services/campus_service.dart';
import 'services/home_service.dart';
import 'services/session.dart';
import 'services/user_service.dart';
import 'widgets/app_sheet.dart';

/// All app routes. The app opens on the opening intro, then the sign-in
/// preview. With no previewed user, everything else redirects to /preview;
/// once a role is picked, the app opens on Home (spec §1.1).
GoRouter createRouter(Session session, UserService userService, HomeService homeService,
    CampusService campusService) {
  final rootKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/opening',
    // Play the intro on every app open, even when a browser reload still
    // holds the last address (e.g. /#/home).
    overridePlatformDefaultLocation: true,
    refreshListenable: session,
    redirect: (context, state) {
      final beforeSignIn = const {'/opening', '/preview'}.contains(state.matchedLocation);
      if (session.user == null) return beforeSignIn ? null : '/preview';
      if (beforeSignIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/opening', builder: (context, state) => const OpeningScreen()),
      GoRoute(
        path: '/preview',
        builder: (context, state) => PreviewScreen(userService: userService),
      ),
      // Quick QR (long-press the middle tab). A router page, so Back closes it.
      GoRoute(
        path: '/qr',
        pageBuilder: (context, state) =>
            AppSheetPage(key: state.pageKey, title: 'Your QR code', child: const QrSheet()),
      ),
      // Attendance scanner and review: full screen over the nav bar, reached
      // only through Start attendance / a finalize task (spec §9.1).
      GoRoute(
        path: '/attendance/:sessionId',
        builder: (context, state) => AttendanceScanScreen(
          campusService: campusService,
          sessionId: state.pathParameters['sessionId']!,
        ),
        routes: [
          GoRoute(
            path: 'review',
            builder: (context, state) => AttendanceReviewScreen(
              campusService: campusService,
              sessionId: state.pathParameters['sessionId']!,
              fromScanner: state.uri.queryParameters['from'] == 'scanner',
            ),
          ),
        ],
      ),
      // indexedStack keeps each tab alive, so its scroll position and
      // inner pages are preserved when switching tabs.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => HomeScreen(homeService: homeService),
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
              builder: (context, state) => LifeHubScreen(campusService: campusService),
              routes: [
                // Student Class screen (spec §7.1).
                GoRoute(
                  path: 'class',
                  builder: (context, state) => ClassScreen(campusService: campusService),
                ),
                // Teacher class management (spec §9.1).
                GoRoute(
                  path: 'classes',
                  builder: (context, state) => ClassesScreen(campusService: campusService),
                  routes: [
                    GoRoute(
                      path: ':classId',
                      builder: (context, state) => ClassDetailScreen(
                        campusService: campusService,
                        classId: state.pathParameters['classId']!,
                      ),
                      routes: [
                        GoRoute(
                          path: 'edit',
                          parentNavigatorKey: rootKey, // form with Save at the bottom
                          builder: (context, state) => EditSessionScreen(
                            campusService: campusService,
                            sessionId: state.uri.queryParameters['session'] ?? '',
                          ),
                        ),
                      ],
                    ),
                  ],
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
              path: '/profile',
              builder: (context, state) =>
                  ProfileScreen(userService: userService, campusService: campusService),
              routes: [
                GoRoute(
                  path: 'settings',
                  parentNavigatorKey: rootKey,
                  pageBuilder: (context, state) => AppSheetPage(
                    key: state.pageKey,
                    title: 'Settings',
                    child: SettingsSheet(userService: userService),
                  ),
                ),
                GoRoute(
                  path: 'edit',
                  parentNavigatorKey: rootKey, // full page over the nav bar (Save sits at the bottom)
                  builder: (context, state) => const EditProfileScreen(),
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
        ],
      ),
    ],
  );
}
