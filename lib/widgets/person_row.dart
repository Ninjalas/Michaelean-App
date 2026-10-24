import 'package:flutter/material.dart';

import '../models/people.dart';
import '../models/user_profile.dart';
import '../services/campus_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import 'user_avatar.dart';

/// A student in a list (connections, requests, search, Going lists): photo,
/// name, section and mutual connections, with an optional action on the right.
class PersonRow extends StatelessWidget {
  static const textIndent = 44 + AppSpacing.md; // divider indent under the name

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
    return InkWell(
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
            // Flexible: with large text, the button gives way instead of overflowing.
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: trailing!),
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
  return switch (p.status) {
    ConnectionStatus.none => OutlinedButton(
        onPressed: () => _connect(context, campus, p),
        child: const Text('Connect'),
      ),
    ConnectionStatus.requestSent => Text('Pending', style: muted),
    ConnectionStatus.requestReceived => Text('Asked you', style: muted),
    ConnectionStatus.connected => Text('Connected', style: muted),
    ConnectionStatus.blocked => null,
  };
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
