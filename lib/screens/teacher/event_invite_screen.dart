import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/attendance.dart';
import '../../models/campus.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_header.dart';

/// Invite students to an event (spec §7.3, §9.2). Invited students are
/// registered automatically, without accept or decline. Mock assumption:
/// only whole sections the teacher teaches can be invited for now.
class EventInviteScreen extends StatefulWidget {
  final CampusService campusService;
  final String eventId;

  const EventInviteScreen({super.key, required this.campusService, required this.eventId});

  @override
  State<EventInviteScreen> createState() => _EventInviteScreenState();
}

class _EventInviteScreenState extends State<EventInviteScreen> {
  Future<(EventDetail?, List<ClassInfo>)>? _data;
  final _picked = <String>{};
  bool _saving = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = SessionScope.of(context).user!;
    _data ??= (
      widget.campusService.loadEvent(user, widget.eventId),
      widget.campusService.loadAssignedClasses(user),
    ).wait;
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
      added = await widget.campusService
          .inviteSections(session.user!, widget.eventId, _picked.toList());
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
          ? 'Everyone in these sections was already registered.'
          : '$added students registered in this preview only. No one was notified.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.muted);
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<(EventDetail?, List<ClassInfo>)>(
          future: _data,
          builder: (context, snap) {
            final event = snap.data?.$1;
            // One row per section, with the subjects taught there.
            final sections = <String, List<String>>{};
            for (final c in snap.data?.$2 ?? const <ClassInfo>[]) {
              sections.putIfAbsent(c.section, () => []).add(c.subject);
            }
            final live = event != null &&
                event.canManage &&
                event.event.status == EventStatus.published &&
                event.event.start.isAfter(DateTime.now());
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
                else if (!live)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    child: Text("You can't invite students to this event.",
                        style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                  )
                else ...[
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                      children: [
                        Text(event.event.title, style: text.titleMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          "Invited students are registered automatically and can't decline. "
                          'In this preview, no one is notified.',
                          style: muted,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text('Your sections', style: text.labelMedium?.copyWith(color: AppColors.muted)),
                        if (sections.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Text('No sections are assigned to you.', style: muted),
                          ),
                        for (final MapEntry(key: section, value: subjects) in sections.entries)
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _picked.contains(section),
                            onChanged: (v) => setState(
                                () => v == true ? _picked.add(section) : _picked.remove(section)),
                            title: Text(section),
                            subtitle: Text(subjects.join(' · ')),
                          ),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Inviting individual students or departments comes later.',
                            style: muted),
                        if (_error != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(_error!, style: text.bodyMedium?.copyWith(color: AppColors.red)),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.lg),
                    child: FilledButton(
                      onPressed: _saving || _picked.isEmpty ? null : _invite,
                      child: Text(_saving
                          ? 'Inviting…'
                          : _picked.length > 1
                              ? 'Invite ${_picked.length} Sections'
                              : 'Invite Section'),
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
}
