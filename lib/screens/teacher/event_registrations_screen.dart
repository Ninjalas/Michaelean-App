import 'package:flutter/material.dart';

import '../../models/campus.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_header.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/user_avatar.dart';

/// Who registered for an event, for its managers only (spec §9.2).
/// Registration isn't attendance.
class EventRegistrationsScreen extends StatefulWidget {
  final CampusService campusService;
  final String eventId;

  const EventRegistrationsScreen(
      {super.key, required this.campusService, required this.eventId});

  @override
  State<EventRegistrationsScreen> createState() => _EventRegistrationsScreenState();
}

class _EventRegistrationsScreenState extends State<EventRegistrationsScreen> {
  Future<List<EventRegistrant>?>? _data;
  String? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (session.user != null && session.dataKey != _loadedFor) {
      _loadedFor = session.dataKey;
      _data = widget.campusService.loadRegistrations(session.user!, widget.eventId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyLarge?.copyWith(color: AppColors.muted);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<EventRegistrant>?>(
          future: _data,
          builder: (context, snap) {
            final list = snap.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BackHeader('Registrations'),
                Expanded(
                  child: snap.hasError
                      ? const Center(child: Text("Couldn't load registrations."))
                      : snap.connectionState != ConnectionState.done
                          ? const Align(
                              alignment: Alignment.topCenter, child: LinearProgressIndicator())
                          : list == null
                              ? Padding(
                                  padding: const EdgeInsets.all(AppSpacing.screen),
                                  child: Text("You can't view this event's registrations.",
                                      style: muted),
                                )
                              : ListView(
                                  padding: const EdgeInsets.fromLTRB(
                                      AppSpacing.screen, 0, AppSpacing.screen, 120),
                                  children: [
                                    Text('${list.length} registered', style: text.titleMedium),
                                    Text("Registration isn't attendance.",
                                        style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                                    const SizedBox(height: AppSpacing.sm),
                                    if (list.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                                        child: Text('No registrations yet.', style: muted),
                                      ),
                                    for (var i = 0; i < list.length; i++) ...[
                                      if (i > 0) const Divider(height: 1, indent: 40 + AppSpacing.md),
                                      _row(list[i]),
                                    ],
                                  ],
                                ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _row(EventRegistrant r) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
      child: Row(
        children: [
          UserAvatar(name: r.name, imageAsset: r.photoAsset, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name, style: text.bodyLarge),
                Text(r.maskedId, style: text.bodyMedium?.copyWith(color: AppColors.muted)),
              ],
            ),
          ),
          if (r.invited) const StatusPill('Invited', tone: PillTone.navy),
        ],
      ),
    );
  }
}
