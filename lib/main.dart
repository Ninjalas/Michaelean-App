import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'services/home_service.dart';
import 'services/session.dart';
import 'services/user_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(MichaeleanApp(userService: MockUserService(), homeService: MockHomeService()));
}

class MichaeleanApp extends StatefulWidget {
  final UserService userService;
  final HomeService homeService;

  const MichaeleanApp({super.key, required this.userService, required this.homeService});

  @override
  State<MichaeleanApp> createState() => _MichaeleanAppState();
}

class _MichaeleanAppState extends State<MichaeleanApp> {
  final _session = Session();
  late final GoRouter _router = createRouter(_session, widget.userService, widget.homeService);

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
