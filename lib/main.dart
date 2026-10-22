import 'package:flutter/foundation.dart' show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'services/campus_service.dart';
import 'services/home_service.dart';
import 'services/session.dart';
import 'services/user_service.dart';
import 'theme/app_theme.dart';

void main() {
  // The bundled fonts' license must ship with the app (About › Open-source licenses).
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
        ['Inter', 'Inter Display'], await rootBundle.loadString('assets/fonts/Inter-OFL.txt'));
  });
  // One campus service for the whole app, so Home and the Class screens
  // share the same (preview-only) attendance state.
  final campus = MockCampusService();
  runApp(MichaeleanApp(
    userService: MockUserService(),
    homeService: MockHomeService(campus: campus),
    campusService: campus,
  ));
}

class MichaeleanApp extends StatefulWidget {
  final UserService userService;
  final HomeService homeService;
  final CampusService campusService;

  const MichaeleanApp({
    super.key,
    required this.userService,
    required this.homeService,
    required this.campusService,
  });

  @override
  State<MichaeleanApp> createState() => _MichaeleanAppState();
}

class _MichaeleanAppState extends State<MichaeleanApp> {
  final _session = Session();
  late final GoRouter _router = createRouter(_session, widget.userService, widget.homeService, widget.campusService);

  @override
  void dispose() {
    _router.dispose();
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      session: _session,
      child: MaterialApp.router(
        title: 'Michaelean',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
