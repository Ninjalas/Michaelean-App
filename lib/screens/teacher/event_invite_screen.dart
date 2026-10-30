import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/campus.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_header.dart';
import '../../widgets/segmented_pills.dart';
import '../../widgets/user_avatar.dart';

/// Invite students to an event (spec §7.3, §9.2): the teacher's sections,
/// all members of any club, or single students (decided 2026-10-30). Picks
/// from the three tabs add up; someone in two picks counts once. Invited
/// students are registered automatically, without accept or decline, and
/// get a notice in this preview's bell. Only eligible students are invited.
class EventInviteScreen extends StatefulWidget {
  final CampusService campusService;
  final String eventId;

  const EventInviteScreen({super.key, required this.campusService, required this.eventId});

  @override
  State<EventInviteScreen> createState() => _EventInviteScreenState();
}

enum _Tab { sections, clubs, students }

class _EventInviteScreenState extends State<EventInviteScreen> {
  Future<(EventDetail?, InviteOptions?)>? _data;
  var _tab = _Tab.sections;
  final _sections = <String>{};
  final _clubs = <String>{};
  final _students = <String>{};
  String _query = '';
  bool _saving = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = SessionScope.of(context).user!;
    _data ??= (
      widget.campusService.loadEvent(user, widget.eventId),
      widget.campusService.loadInviteOptions(user, widget.eventId),
    ).wait;
  }

  /// Everyone the picks would newly register: each student once, only those
  /// who can be invited.
  Set<String> _chosen(InviteOptions o) {
    final can = {for (final s in o.students) if (s.unavailable == null) s.id};
    return {
      for (final g in o.sections) if (_sections.contains(g.id)) ...g.studentIds,
      for (final g in o.clubs) if (_clubs.contains(g.id)) ...g.studentIds,
      ..._students,
    }.where(can.contains).toSet();
  }

  Future<void> _invite() async {
    final session = SessionScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    final int added;
    try {
      added = await widget.campusService.invite(session.user!, widget.eventId,
          sections: _sections.toList(), orgIds: _clubs.toList(), studentIds: _students.toList());
    } on StateError catch (e) {
      if (mounted) setState(() => _error = 'No one was invited. ${e.message}');
      return;
    } catch (_) {
      if (mounted) setState(() => _error = "No one was invited. Couldn't reach the service.");
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    router.pop();
    session.refresh();
    messenger.showSnackBar(SnackBar(
      content: Text(added == 0
          ? 'Everyone you picked was already registered.'
          : '$added ${added == 1 ? 'student' : 'students'} registered in this preview only. '
              'Their bell shows it in this preview; nothing is really sent.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.muted);
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<(EventDetail?, InviteOptions?)>(
          future: _data,
          builder: (context, snap) {
            final event = snap.data?.$1;
            final options = snap.data?.$2;
            final chosen = options == null ? const <String>{} : _chosen(options);
            final spots = options?.spotsLeft;
            final tooMany = spots != null && chosen.length > spots;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BackHeader('Invite Students'),
                if (snap.connectionState != ConnectionState.done)
                  const LinearProgressIndicator()
                else if (snap.hasError)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    child: Text("Couldn't load this event.",
                        style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                  )
                else if (event == null || options == null)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    child: Text("You can't invite students to this event.",
                        style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(event.event.title, style: text.titleMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          "Invited students are registered automatically and can't decline. "
                          'In this preview, only their bell shows it.',
                          style: muted,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SegmentedPills<_Tab>(
                          segments: const [
                            (_Tab.sections, 'Sections'),
                            (_Tab.clubs, 'Clubs'),
                            (_Tab.students, 'Students'),
                          ],
                          selected: _tab,
                          onChanged: (t) => setState(() => _tab = t),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: switch (_tab) {
                      _Tab.sections => _groups(options, options.sections, _sections,
                          empty: 'No sections are assigned to you.'),
                      _Tab.clubs => _groups(options, options.clubs, _clubs,
                          empty: 'No clubs have member lists.'),
                      _Tab.students => _studentList(options),
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null || tooMany || spots != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Text(
                              _error ??
                                  (tooMany
                                      ? 'Only $spots spots left. Pick fewer students.'
                                      : '$spots spots left.'),
                              style: _error != null || tooMany
                                  ? text.bodyMedium?.copyWith(color: AppColors.red)
                                  : muted,
                            ),
                          ),
                        FilledButton(
                          onPressed: _saving || chosen.isEmpty || tooMany ? null : _invite,
                          child: Text(_saving
                              ? 'Inviting…'
                              : chosen.isEmpty
                                  ? 'Invite Students'
                                  : 'Invite ${chosen.length} '
                                      '${chosen.length == 1 ? 'Student' : 'Students'}'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// Sections or clubs, each ticked as a whole.
  Widget _groups(InviteOptions o, List<InviteGroup> groups, Set<String> picked,
      {required String empty}) {
    final muted = Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted);
    final can = {for (final s in o.students) if (s.unavailable == null) s.id};
    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Text(empty, style: muted),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      children: [
        for (final g in groups)
          Builder(builder: (context) {
            final n = g.studentIds.where(can.contains).length;
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: picked.contains(g.id),
              onChanged: (v) => setState(() => v == true ? picked.add(g.id) : picked.remove(g.id)),
              title: Text(g.name),
              // Who of them this would register, when it isn't everyone.
              subtitle: Text(n == g.studentIds.length
                  ? g.detail
                  : '${g.detail} · ${n == 0 ? 'none' : n} can be invited'),
            );
          }),
      ],
    );
  }

  /// Any student, found by name; those who can't come are shown with why.
  Widget _studentList(InviteOptions o) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.muted);
    final q = _query.trim().toLowerCase();
    final list = [for (final s in o.students) if (s.name.toLowerCase().contains(q)) s];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      children: [
        const SizedBox(height: AppSpacing.md),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(
            hintText: 'Search students by name',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('Sample students from the class lists.', style: muted),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text('No students match "$_query".', style: muted),
          ),
        for (final s in list)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            secondary: UserAvatar(name: s.name, imageAsset: s.photoAsset, size: 40),
            value: s.unavailable == null && _students.contains(s.id),
            onChanged: s.unavailable != null
                ? null
                : (v) => setState(() => v == true ? _students.add(s.id) : _students.remove(s.id)),
            title: Text(s.name),
            subtitle: Text(s.unavailable ?? '${s.section} · ${s.maskedId}'),
          ),
      ],
    );
  }
}
