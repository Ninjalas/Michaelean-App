import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Michaelean Life pages that Home and Profile also have their own copy of
/// (router.dart builds the copies from this). A page opened from Home then
/// stays in Home, so Back returns there instead of staying in Michaelean
/// Life (decided 2026-10-24).
const tabCopies = {
  '/home': ['class', 'classes', 'clearance', 'events', 'organizations', 'people'],
  '/profile': ['classes', 'events', 'people'],
};

/// The tab the current page belongs to: '/home', '/life' or '/profile'.
/// Pages over the nav bar (attendance) count as Michaelean Life.
String tabRoot(BuildContext context) {
  final path = GoRouterState.of(context).uri.path;
  for (final tab in tabCopies.keys) {
    if (path == tab || path.startsWith('$tab/')) return tab;
  }
  return '/life';
}

/// [path] opened in the current tab when it is a Michaelean Life page this
/// tab has a copy of, e.g. '/life/events/ev1' → '/home/events/ev1' from
/// Home. Any other path is returned as it is.
String inTab(BuildContext context, String path) {
  if (!path.startsWith('/life/')) return path;
  final tab = tabRoot(context);
  final section = path.substring('/life/'.length).split(RegExp('[/?]')).first;
  return tabCopies[tab]?.contains(section) ?? false
      ? '$tab${path.substring('/life'.length)}'
      : path;
}
