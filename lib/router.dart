import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'screens/shared/about_screen.dart';
import 'screens/shared/account_security_screen.dart';
import 'screens/shared/app_shell.dart';
import 'screens/shared/coming_soon_screen.dart';
import 'screens/shared/edit_profile_screen.dart';
import 'screens/shared/event_detail_screen.dart';
import 'screens/shared/event_history_screen.dart';
import 'screens/shared/events_screen.dart';
import 'screens/shared/going_screen.dart';
import 'screens/shared/help_screen.dart';
import 'screens/shared/home_screen.dart';
import 'screens/shared/life_hub_screen.dart';
import 'screens/shared/notification_settings_screen.dart';
import 'screens/shared/notifications_sheet.dart';
import 'screens/shared/people_screen.dart';
import 'screens/shared/person_screen.dart';
import 'screens/shared/personal_info_screen.dart';
import 'screens/shared/opening_screen.dart';
import 'screens/shared/privacy_screen.dart';
import 'screens/shared/profile_screen.dart';
import 'screens/shared/qr_sheet.dart';
import 'screens/shared/settings_sheet.dart';
import 'screens/student/class_screen.dart';
import 'screens/student/clearance_item_screen.dart';
import 'screens/student/clearance_screen.dart';
import 'screens/student/grades_screen.dart';
import 'screens/student/organization_screen.dart';
import 'screens/student/organizations_screen.dart';
import 'screens/teacher/attendance_review_screen.dart';
import 'screens/teacher/attendance_scan_screen.dart';
import 'screens/teacher/class_detail_screen.dart';
import 'screens/teacher/classes_screen.dart';
import 'screens/teacher/club_add_member_screen.dart';
import 'screens/teacher/club_info_screen.dart';
import 'screens/teacher/club_manage_screen.dart';
import 'screens/teacher/clearance_case_screen.dart';
import 'screens/teacher/clearance_desk_screen.dart';
import 'screens/teacher/create_menu.dart';
import 'screens/teacher/edit_session_screen.dart';
import 'screens/teacher/event_checkin_screen.dart';
import 'screens/teacher/event_form_screen.dart';
import 'screens/teacher/event_invite_screen.dart';
import 'screens/teacher/event_registrations_screen.dart';
import 'screens/teacher/post_form_screen.dart';
import 'screens/shared/post_detail_screen.dart';
import 'screens/shared/preview_screen.dart';
import 'services/campus_service.dart';
import 'services/home_service.dart';
import 'services/session.dart';
import 'services/user_service.dart';
import 'models/feed.dart';
import 'utils/tab_path.dart';
import 'widgets/app_sheet.dart';

/// All app routes. The app opens on the opening intro, then the sign-in
/// preview. With no previewed user, everything else redirects to /preview;
/// once a role is picked, the app opens on Home (spec §1.1).
GoRouter createRouter(Session session, UserService userService, HomeService homeService,
    CampusService campusService) {
  final rootKey = GlobalKey<NavigatorState>();
  // Michaelean Life pages that Home and Profile also open in their own tab,
  // so Back returns where the user was (utils/tab_path.dart).
  final shared = <String, GoRoute Function()>{
    // Student Class screen (spec §7.1).
    'class': () => GoRoute(
      path: 'class',
      builder: (context, state) => ClassScreen(campusService: campusService),
    ),
    // Teacher class management (spec §9.1).
    'classes': () => GoRoute(
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
    // Clearance (spec §7.5).
    'clearance': () => GoRoute(
      path: 'clearance',
      builder: (context, state) => ClearanceScreen(campusService: campusService),
      routes: [
        GoRoute(
          path: ':itemId',
          builder: (context, state) => ClearanceItemScreen(
            campusService: campusService,
            itemId: state.pathParameters['itemId']!,
          ),
        ),
      ],
    ),
    // Organizations (spec §7.4). An event opened from an
    // organization is pushed on top, so Back returns to it.
    'organizations': () => GoRoute(
      path: 'organizations',
      builder: (context, state) =>
          OrganizationsScreen(campusService: campusService),
      routes: [
        GoRoute(
          path: ':orgId',
          builder: (context, state) => OrganizationScreen(
            campusService: campusService,
            homeService: homeService,
            orgId: state.pathParameters['orgId']!,
          ),
          routes: [
            GoRoute(
              path: 'post/:postId',
              routes: [
                // A club post its adviser wrote in this preview.
                GoRoute(
                  path: 'edit',
                  parentNavigatorKey: rootKey,
                  builder: (context, state) => PostFormScreen(
                    homeService: homeService,
                    campusService: campusService,
                    postId: state.pathParameters['postId']!,
                  ),
                ),
              ],
              builder: (context, state) => PostDetailScreen(
                postId: state.pathParameters['postId']!,
                homeService: homeService,
              ),
            ),
          ],
        ),
      ],
    ),
    // People search, and other students' profiles (spec §10.1).
    'people': () => GoRoute(
      path: 'people',
      builder: (context, state) => PeopleScreen(campusService: campusService),
      routes: [
        GoRoute(
          path: ':personId',
          builder: (context, state) => PersonScreen(
            campusService: campusService,
            personId: state.pathParameters['personId']!,
          ),
        ),
      ],
    ),
    // Events (spec §7.3, §9.2). Forms cover the nav bar, like
    // Edit Session, since their buttons sit at the bottom.
    'events': () => GoRoute(
      path: 'events',
      builder: (context, state) => EventsScreen(campusService: campusService),
      routes: [
        GoRoute(
          path: 'new',
          parentNavigatorKey: rootKey,
          builder: (context, state) => EventFormScreen(campusService: campusService),
        ),
        GoRoute(
          path: ':eventId',
          builder: (context, state) => EventDetailScreen(
            campusService: campusService,
            eventId: state.pathParameters['eventId']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              parentNavigatorKey: rootKey,
              builder: (context, state) => EventFormScreen(
                campusService: campusService,
                eventId: state.pathParameters['eventId']!,
              ),
            ),
            GoRoute(
              path: 'invite',
              parentNavigatorKey: rootKey,
              builder: (context, state) => EventInviteScreen(
                campusService: campusService,
                eventId: state.pathParameters['eventId']!,
              ),
            ),
            GoRoute(
              path: 'checkin',
              parentNavigatorKey: rootKey, // full-screen scanner
              builder: (context, state) => EventCheckInScreen(
                campusService: campusService,
                eventId: state.pathParameters['eventId']!,
              ),
            ),
            GoRoute(
              path: 'registrations',
              builder: (context, state) => EventRegistrationsScreen(
                campusService: campusService,
                eventId: state.pathParameters['eventId']!,
              ),
            ),
            // Who's going (or went), spec §10.1.
            GoRoute(
              path: 'going',
              builder: (context, state) => GoingScreen(
                campusService: campusService,
                eventId: state.pathParameters['eventId']!,
              ),
            ),
          ],
        ),
      ],
    ),
  };

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
            routes: [
              // A student's profile, opened over the review (it sits above the tabs).
              GoRoute(
                path: 'people/:personId',
                builder: (context, state) => PersonScreen(
                  campusService: campusService,
                  personId: state.pathParameters['personId']!,
                ),
              ),
            ],
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
                  routes: [
                    GoRoute(
                      path: 'edit',
                      parentNavigatorKey: rootKey,
                      builder: (context, state) => PostFormScreen(
                        homeService: homeService,
                        campusService: campusService,
                        postId: state.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
                // The + menu and the post form cover the nav bar too.
                GoRoute(
                  path: 'create',
                  parentNavigatorKey: rootKey,
                  pageBuilder: (context, state) => CreateMenuPage(
                    key: state.pageKey,
                    bottom: state.extra as double? ?? 100, // no extra after a browser reload
                  ),
                ),
                GoRoute(
                  path: 'compose/:kind',
                  parentNavigatorKey: rootKey,
                  builder: (context, state) => PostFormScreen(
                    homeService: homeService,
                    campusService: campusService,
                    kind: PostKind.values.asNameMap()[state.pathParameters['kind']],
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
                for (final page in tabCopies['/home']!) shared[page]!(),
                // Event history, from the attendance stats.
                GoRoute(
                  path: 'history',
                  builder: (context, state) =>
                      EventHistoryScreen(campusService: campusService),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/life',
              builder: (context, state) => LifeHubScreen(campusService: campusService),
              routes: [
                for (final make in shared.values) make(),
                // The student's own grades (spec §7.6).
                GoRoute(
                  path: 'grades',
                  builder: (context, state) => GradesScreen(campusService: campusService),
                  routes: [
                    // How the overall average is counted, for one semester.
                    GoRoute(
                      path: 'average',
                      parentNavigatorKey: rootKey, // pop-up covers the nav bar too
                      pageBuilder: (context, state) => AppSheetPage(
                        key: state.pageKey,
                        title: 'How your average is counted',
                        child: AverageSheet(
                          campusService: campusService,
                          semester: int.tryParse(state.uri.queryParameters['sem'] ?? '') ?? 0,
                        ),
                      ),
                    ),
                  ],
                ),
                // Staff verification (spec §9.3).
                GoRoute(
                  path: 'verify',
                  builder: (context, state) => ClearanceDeskScreen(campusService: campusService),
                  routes: [
                    GoRoute(
                      path: ':studentId',
                      parentNavigatorKey: rootKey, // form with its button at the bottom
                      builder: (context, state) => ClearanceCaseScreen(
                        campusService: campusService,
                        studentId: state.pathParameters['studentId']!,
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  // Manage club, for the club's adviser (decided 2026-10-23).
                  path: 'clubs/:orgId',
                  builder: (context, state) => ClubManageScreen(
                    campusService: campusService,
                    homeService: homeService,
                    orgId: state.pathParameters['orgId']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'add',
                      builder: (context, state) => ClubAddMemberScreen(
                        campusService: campusService,
                        orgId: state.pathParameters['orgId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'info',
                      parentNavigatorKey: rootKey,
                      builder: (context, state) => ClubInfoScreen(
                        campusService: campusService,
                        orgId: state.pathParameters['orgId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'post',
                      parentNavigatorKey: rootKey,
                      builder: (context, state) => PostFormScreen(
                        homeService: homeService,
                        campusService: campusService,
                        orgId: state.pathParameters['orgId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'event',
                      parentNavigatorKey: rootKey,
                      builder: (context, state) => EventFormScreen(
                        campusService: campusService,
                        hostOrgId: state.pathParameters['orgId']!,
                      ),
                    ),
                  ],
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
                  path: 'privacy',
                  builder: (context, state) => PrivacyScreen(campusService: campusService),
                ),
                for (final page in tabCopies['/profile']!) shared[page]!(),
                GoRoute(
                  path: 'edit',
                  parentNavigatorKey: rootKey, // full page over the nav bar (Save sits at the bottom)
                  builder: (context, state) => const EditProfileScreen(),
                ),
                // Settings pages (spec §11).
                GoRoute(
                    path: 'personal', builder: (context, state) => const PersonalInfoScreen()),
                GoRoute(
                    path: 'security', builder: (context, state) => const AccountSecurityScreen()),
                GoRoute(
                    path: 'notifications',
                    builder: (context, state) => const NotificationSettingsScreen()),
                GoRoute(
                    path: 'help',
                    builder: (context, state) => HelpScreen(campusService: campusService)),
                GoRoute(path: 'about', builder: (context, state) => const AboutScreen()),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
}
