import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/campus.dart';
import '../../models/guest.dart';
import '../../models/user_profile.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_header.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/user_avatar.dart';

/// An event's guest list (spec §7.3), the same for both roles.
///
/// Only registered guests and the event's managers get the list; everyone
/// else sees "Register to view the guest list". The service decides this, not
/// the screen: hiding a button is not security (spec §12). The visibility
/// rules themselves are open decision 4.
class GuestListScreen extends StatefulWidget {
  final CampusService campusService;
  final String eventId;

  const GuestListScreen({super.key, required this.campusService, required this.eventId});

  @override
  State<GuestListScreen> createState() => _GuestListScreenState();
}

class _GuestData {
  final CampusEvent? event; // null: not available to this user
  final List<EventGuest>? guests; // null: this user may not view the list

  const _GuestData({this.event, this.guests});
}

class _GuestListScreenState extends State<GuestListScreen> {
  final _search = TextEditingController();
  Future<_GuestData>? _data;
  String? _loadedFor; // Session.dataKey the data belongs to
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload after registering or cancelling (Session.refresh).
    final session = SessionScope.of(context);
    if (session.user != null && session.dataKey != _loadedFor) {
      _loadedFor = session.dataKey;
      _data = _load(session.user!);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<_GuestData> _load(UserProfile user) async {
    final event = await widget.campusService.loadEvent(user, widget.eventId);
    if (event == null) return const _GuestData();
    final guests = await widget.campusService.loadGuests(user, widget.eventId);
    return _GuestData(event: event, guests: guests);
  }

  void _retry() => setState(() => _data = _load(SessionScope.of(context).user!));

  @override
  Widget build(BuildContext context) {
    final user = SessionScope.of(context).user;
    if (user == null) return const SizedBox.shrink(); // preview just ended

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<_GuestData>(
          future: _data,
          builder: (context, snap) {
            final d = snap.data;
            final list = d?.guests;
            return Column(
              children: [
                BackHeader(list == null ? 'Guests' : '${list.length} Guests'),
                Expanded(child: _body(context, user, snap, d)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(BuildContext context, UserProfile user, AsyncSnapshot<_GuestData> snap,
      _GuestData? d) {
    final text = Theme.of(context).textTheme;
    if (snap.hasError) {
      return _Message(
        icon: Icons.error_outline_rounded,
        title: "Couldn't load guests",
        body: 'Check your connection and try again.',
        action: OutlinedButton(onPressed: _retry, child: const Text('Retry')),
      );
    }
    if (snap.connectionState != ConnectionState.done || d == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (d.event == null) {
      return const _Message(
        icon: Icons.event_busy_outlined,
        title: 'Event not available',
        body: "This event doesn't exist or isn't open to you.",
      );
    }
    final guests = d.guests;
    if (guests == null) {
      return _Message(
        icon: Icons.group_outlined,
        title: 'Register to view the guest list',
        body: 'The full guest list is only available to registered guests.',
        action: FilledButton(
          onPressed: () => context.push('/life/events/${widget.eventId}/register'),
          child: const Text('Register'),
        ),
      );
    }
    if (guests.isEmpty) {
      return const _Message(
        icon: Icons.group_outlined,
        title: 'No guests yet',
        body: 'No one has registered for this event.',
      );
    }

    final q = _query.trim().toLowerCase();
    final shown = q.isEmpty
        ? guests
        : guests
            .where((g) =>
                g.name.toLowerCase().contains(q) ||
                g.course.toLowerCase().contains(q) ||
                g.yearLevel.toLowerCase().contains(q))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.sm),
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search name, course, or year',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Registered guests. Registration is not attendance.',
                style: text.bodyMedium?.copyWith(color: AppColors.muted)),
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? _Message(
                  icon: Icons.search_off_rounded,
                  title: 'No results',
                  body: 'No guests match "${_query.trim()}".',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 120),
                  itemCount: shown.length,
                  itemBuilder: (_, i) => _GuestRow(guest: shown[i], isMe: shown[i].id == user.id),
                ),
        ),
      ],
    );
  }
}

class _GuestRow extends StatelessWidget {
  final EventGuest guest;
  final bool isMe;

  const _GuestRow({required this.guest, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          UserAvatar(name: guest.name, imageAsset: guest.photoAsset, size: 44),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(guest.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleMedium),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const StatusPill('You', tone: PillTone.navy),
                    ],
                  ],
                ),
                Text('${guest.course} · ${guest.yearLevel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon, short title, one muted sentence, optional action (spec §2.1).
class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  const _Message({required this.icon, required this.title, required this.body, this.action});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.muted),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(body,
                style: text.bodyMedium?.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: AppSpacing.lg), action!],
          ],
        ),
      ),
    );
  }
}
