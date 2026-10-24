import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/people.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_header.dart';
import '../../widgets/fade_switch.dart';
import '../../widgets/person_row.dart';
import '../../widgets/user_avatar.dart';

/// "Andrea, Carlo and 14 others are going" (or "went"). The viewer shows as
/// "You"; people whose settings hide them are only counted.
String goingLine(EventAttendees a) {
  if (a.total == 0) {
    return a.past ? 'No recorded attendance yet.' : 'No one has registered yet.';
  }
  final names = [
    if (a.includesViewer) 'You',
    for (final p in a.shown) p.name.split(' ').first,
  ].take(2).toList();
  final rest = a.total - names.length;
  if (names.isEmpty) return '${a.total} ${a.past ? 'went' : 'going'}';
  final verb = a.past
      ? 'went'
      : names.length == 1 && rest == 0 && names.first != 'You'
          ? 'is going'
          : 'are going';
  final who = rest == 0
      ? names.join(' and ')
      : '${names.join(', ')} and $rest ${rest == 1 ? 'other' : 'others'}';
  return '$who $verb';
}

/// Up to four overlapping photos of the people named, connections first.
class FacesRow extends StatelessWidget {
  final List<PersonSummary> people;

  const FacesRow({super.key, required this.people});

  @override
  Widget build(BuildContext context) {
    const size = 32.0, step = 22.0;
    final shown = people.take(4).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: SizedBox(
        width: size + step * (shown.length - 1),
        height: size,
        child: Stack(
          children: [
            for (var i = 0; i < shown.length; i++)
              Positioned(
                left: i * step,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: UserAvatar(
                      name: shown[i].name, imageAsset: shown[i].photoAsset, size: size - 4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The full Going (or Went) list for an event (spec §10.1): the people the
/// viewer may see, connections first, each with Connect where it applies;
/// everyone else is counted at the end.
class GoingScreen extends StatefulWidget {
  final CampusService campusService;
  final String eventId;

  const GoingScreen({super.key, required this.campusService, required this.eventId});

  @override
  State<GoingScreen> createState() => _GoingScreenState();
}

class _GoingScreenState extends State<GoingScreen> {
  Future<EventAttendees?>? _data;
  String? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (session.user != null && session.dataKey != _loadedFor) {
      _loadedFor = session.dataKey; // reload after a Connect
      _data = widget.campusService.loadEventAttendees(session.user!, widget.eventId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.muted);
    // Profiles open in the tab this list was opened from.
    final tab =
        GoRouterState.of(context).uri.path.startsWith('/profile') ? '/profile' : '/life';
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<EventAttendees?>(
          future: _data,
          builder: (context, snap) {
            final a = snap.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BackHeader(a == null ? 'Going' : (a.past ? 'Went' : 'Going')),
                Expanded(
                  child: FadeSwitch(
                    loaded: snap.hasData || snap.hasError || snap.connectionState == ConnectionState.done,
                    child: snap.hasError
                        ? const Center(child: Text("Couldn't load who's going."))
                        : !snap.hasData && snap.connectionState != ConnectionState.done
                            ? const Align(
                                alignment: Alignment.topCenter, child: LinearProgressIndicator())
                            : a == null
                                ? Padding(
                                    padding: const EdgeInsets.all(AppSpacing.screen),
                                    child: Text("This event isn't available to you.",
                                        style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                                  )
                                : ListView(
                                    padding: const EdgeInsets.fromLTRB(
                                        AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 120),
                                    children: [
                                      Text(goingLine(a), style: text.titleMedium),
                                      for (var i = 0; i < a.shown.length; i++) ...[
                                        if (i > 0)
                                          const Divider(height: 1, indent: PersonRow.textIndent),
                                        PersonRow(
                                          person: a.shown[i],
                                          onTap: () =>
                                              context.push('$tab/people/${a.shown[i].id}'),
                                          trailing: connectAction(
                                              context, widget.campusService, a.shown[i]),
                                        ),
                                      ],
                                      if (a.others > 0) ...[
                                        const SizedBox(height: AppSpacing.md),
                                        Text(
                                          '${a.others} ${a.others == 1 ? 'other isn\'t' : 'others aren\'t'} '
                                          'named: their privacy settings hide '
                                          "${a.past ? 'their event history' : 'their upcoming events'}"
                                          ', or they are sample registrations without names.',
                                          style: muted,
                                        ),
                                      ],
                                    ],
                                  ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
