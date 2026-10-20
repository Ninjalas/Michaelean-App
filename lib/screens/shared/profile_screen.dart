import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/event_record.dart';
import '../../models/user_profile.dart';
import '../../services/session.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/content_row.dart';
import '../../widgets/profile_coin.dart';
import '../../widgets/round_icon_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_pill.dart';

/// Shared social-identity profile for both roles (spec §10).
class ProfileScreen extends StatefulWidget {
  final UserService userService;

  const ProfileScreen({super.key, required this.userService});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<List<EventRecord>>? _history;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = SessionScope.of(context).user;
    if (user != null) _history ??= widget.userService.loadEventHistory(user);
  }

  void _openSoon(String what) => context
      .push(Uri(path: '/profile/soon', queryParameters: {'what': what}).toString());

  @override
  Widget build(BuildContext context) {
    final user = SessionScope.of(context).user;
    if (user == null) return const SizedBox.shrink(); // preview just ended
    final text = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.md, AppSpacing.screen, 120),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: RoundIconButton(
              icon: Icons.settings_outlined,
              tooltip: 'Settings',
              onPressed: () => context.push('/profile/settings'),
            ),
          ),
          Center(
            child: ProfileCoin(
              name: user.fullName,
              photoAsset: user.photoAsset,
              qrData: user.qrToken,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text('Tap photo for QR',
                style: text.bodyMedium?.copyWith(color: AppColors.muted)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(user.fullName, style: text.headlineMedium),
          const SizedBox(height: 2),
          Text(
            '${user.role == UserRole.student ? 'Student' : 'Teacher'} · ${user.designation}',
            style: text.bodyLarge,
          ),
          Text('ID ${user.maskedId}',
              style: text.bodyMedium?.copyWith(color: AppColors.muted)),
          const SizedBox(height: AppSpacing.md),
          // Official tags: assigned by the school, not editable here (spec §5).
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [for (final t in user.tags) StatusPill(t.label, tone: _tone(t.kind))],
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            onPressed: () => _openSoon('Edit Profile'),
            child: const Text('Edit Profile'),
          ),
          if (user.about != null) ...[
            const SectionHeader('About'),
            Text(user.about!, style: text.bodyLarge),
          ],
          const SectionHeader('Event History'),
          FutureBuilder<List<EventRecord>>(
            future: _history,
            builder: (context, snap) {
              final items = snap.data;
              if (snap.hasError) return const Text("Couldn't load event history.");
              if (items == null) return const LinearProgressIndicator();
              if (items.isEmpty) {
                return Text('No recorded events yet.',
                    style: text.bodyLarge?.copyWith(color: AppColors.muted));
              }
              return Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: ContentRow.textIndent),
                    ContentRow(
                      title: items[i].eventName,
                      meta: formatDate(items[i].date),
                      metaIcon: Icons.calendar_today_outlined,
                      imageAsset: items[i].imageAsset,
                      placeholderIcon: Icons.event_outlined,
                      pill: StatusPill(
                        '${_statusLabel(items[i].status)} · ${_roleLabel(items[i].role)}',
                        tone: PillTone.green,
                      ),
                      onTap: () => _openSoon(items[i].eventName),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  PillTone _tone(TagKind k) => switch (k) {
        TagKind.institution || TagKind.school || TagKind.department => PillTone.navy,
        TagKind.organization => PillTone.neutral,
        TagKind.officer => PillTone.red,
      };

  String _statusLabel(ParticipationStatus s) => switch (s) {
        ParticipationStatus.attended => 'Attended',
        ParticipationStatus.participated => 'Participated',
      };

  String _roleLabel(EventRole r) => switch (r) {
        EventRole.participant => 'Participant',
        EventRole.organizer => 'Organizer',
        EventRole.host => 'Host',
        EventRole.volunteer => 'Volunteer',
      };
}
