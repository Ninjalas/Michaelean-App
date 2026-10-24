import 'package:flutter/material.dart';

import '../models/people.dart';
import '../models/user_profile.dart';
import '../services/campus_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import 'fade_switch.dart';
import 'pressable.dart';
import 'user_avatar.dart';

/// A student in a list (connections, requests, search, Going lists): photo,
/// name, section and mutual connections, with an optional action on the right.
class PersonRow extends StatelessWidget {
  static const textIndent = 44 + AppSpacing.md; // divider indent under the name
  static const maxTrailingWidth = 160.0; // the button never squeezes the name more

  final PersonSummary person;
  final VoidCallback onTap;
  final Widget? trailing;

  const PersonRow({super.key, required this.person, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final mutual = person.mutual == 0
        ? ''
        : ' · ${person.mutual} mutual';
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            UserAvatar(name: person.name, imageAsset: person.photoAsset, size: 44),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(person.name, style: text.titleMedium),
                  Text('${person.section}$mutual',
                      style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                ],
              ),
            ),
            // Right-aligned at its own width; capped so with large text the
            // button gives way instead of overflowing. (A Flexible here would
            // split the row with the name and pull the button to the middle.)
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxTrailingWidth),
                child: trailing!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The right side of a person row in lists: a Connect button, or where you
/// stand with them. Accepting or removing happens on their profile. Null for
/// teachers, who don't connect, and for yourself.
Widget? connectAction(BuildContext context, CampusService campus, PersonSummary p) {
  final me = SessionScope.of(context).user;
  if (me == null || me.role != UserRole.student || me.id == p.id) return null;
  final muted = Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted);
  if (p.status == ConnectionStatus.blocked) return null;
  return StateFade(
    state: p.status,
    child: switch (p.status) {
      ConnectionStatus.none => OutlinedButton(
          onPressed: () => _connect(context, campus, p),
          child: const Text('Connect'),
        ),
      ConnectionStatus.requestSent => Text('Pending', style: muted),
      ConnectionStatus.requestReceived => Text('Asked you', style: muted),
      ConnectionStatus.connected => Text('Connected', style: muted),
      ConnectionStatus.blocked => const SizedBox.shrink(), // returned null above
    },
  );
}

/// Sends a request from a list, then reloads and says so honestly.
Future<void> _connect(BuildContext context, CampusService campus, PersonSummary p) async {
  final session = SessionScope.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    await campus.sendConnectRequest(session.user!, p.id);
  } on StateError catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Not sent. ${e.message}')));
    return;
  } catch (_) {
    messenger.showSnackBar(
        const SnackBar(content: Text("Not sent. Couldn't reach the service.")));
    return;
  }
  session.refresh();
  messenger.showSnackBar(
      SnackBar(content: Text('Request sent to ${p.name} in this preview only.')));
}
