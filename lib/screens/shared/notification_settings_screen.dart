import 'package:flutter/material.dart';

import '../../models/feed.dart';
import '../../services/notification_prefs.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_header.dart';
import '../../widgets/inset_list.dart';

/// Notifications (spec §11): one switch per type, saved on this device.
/// Switching a type off hides it from the notifications list; urgent ones
/// always show. No real notifications are sent in the prototype.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  static const _types = [
    (NotificationKind.announcement, 'Announcements', Icons.campaign_outlined),
    (NotificationKind.news, 'School news', Icons.article_outlined),
    (NotificationKind.organization, 'Organizations', Icons.groups_outlined),
    (NotificationKind.schedule, 'Schedule changes', Icons.event_note_outlined),
    (NotificationKind.attendance, 'Attendance', Icons.how_to_reg_outlined),
    (NotificationKind.clearance, 'Clearance', Icons.fact_check_outlined),
    (NotificationKind.connection, 'Connections', Icons.person_add_alt_1_outlined),
  ];

  Set<NotificationKind>? _muted;

  @override
  void initState() {
    super.initState();
    NotificationPrefs.muted().then((m) {
      if (mounted) setState(() => _muted = m);
    });
  }

  Future<void> _set(NotificationKind kind, bool on) async {
    final messenger = ScaffoldMessenger.of(context);
    final session = SessionScope.of(context);
    setState(() => on ? _muted!.remove(kind) : _muted!.add(kind));
    if (await NotificationPrefs.set(kind, on)) {
      session.refresh(); // the bell's dot counts only shown types
    } else {
      // Say so, and put the switch back: it wasn't saved.
      if (mounted) setState(() => on ? _muted!.add(kind) : _muted!.remove(kind));
      messenger.showSnackBar(
          const SnackBar(content: Text("Couldn't save this setting on this device.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.muted);
    final off = _muted;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BackHeader('Notifications'),
            if (off == null)
              const LinearProgressIndicator()
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 120),
                  children: [
                    Text('Show in your notifications', style: text.labelMedium?.copyWith(
                        color: AppColors.muted)),
                    const SizedBox(height: AppSpacing.sm),
                    InsetGroup([
                      for (final (kind, label, icon) in _types)
                        SwitchListTile(
                          value: !off.contains(kind),
                          onChanged: (on) => _set(kind, on),
                          secondary: Icon(icon, color: AppColors.ink),
                          title: Text(label),
                          activeThumbColor: AppColors.white,
                          activeTrackColor: AppColors.navy,
                        ),
                    ]),
                    const SizedBox(height: AppSpacing.md),
                    Text('Urgent notifications always show, even when their type is off.',
                        style: muted),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Saved on this device. In this preview no real notifications are sent; '
                      'these switches only change what the bell shows.',
                      style: muted,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
