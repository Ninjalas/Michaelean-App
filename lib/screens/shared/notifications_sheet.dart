import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/feed.dart';
import '../../services/home_service.dart';
import '../../services/notification_prefs.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../utils/tab_path.dart';
import '../../widgets/fade_switch.dart';
import '../../widgets/pressable.dart';

/// Recent notifications, shown inside the shared pop-up and grouped into
/// Today / Earlier (spec §6). Opening one marks it read and navigates; it
/// changes no school record. Types switched off in Settings are hidden,
/// except urgent ones.
class NotificationsSheet extends StatefulWidget {
  final HomeService homeService;

  const NotificationsSheet({super.key, required this.homeService});

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  Future<List<AppNotification>>? _items;
  int _hidden = 0; // switched off in Settings

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _items ??= _load();
  }

  Future<List<AppNotification>> _load() async {
    final (all, muted) = await (
      widget.homeService.loadNotifications(SessionScope.of(context).user!),
      NotificationPrefs.muted(),
    ).wait;
    final shown = all.where((n) => NotificationPrefs.shows(n, muted)).toList();
    _hidden = all.length - shown.length;
    return shown;
  }

  void _openSettings() {
    final router = GoRouter.of(context);
    router.pop(); // close the pop-up first
    router.go('/profile/notifications');
  }

  Future<void> _markAllRead(List<AppNotification> items) async {
    await widget.homeService.markNotificationsRead(
        SessionScope.of(context).user!, items.where((n) => !n.read).map((n) => n.id));
    final read = [for (final n in items) n.markedRead()];
    if (mounted) setState(() { _items = Future.value(read); });
  }

  Future<void> _open(AppNotification n) async {
    final router = GoRouter.of(context);
    final route = n.route == null ? null : inTab(context, n.route!);
    await widget.homeService.markNotificationsRead(SessionScope.of(context).user!, [n.id]);
    router.pop(); // close the pop-up first
    router.push(n.postId != null
        ? '/home/post/${n.postId}'
        : route ?? Uri(path: '/home/soon', queryParameters: {'what': n.title}).toString());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppNotification>>(
      future: _items,
      builder: fadeOnLoad((context, snap) {
        final now = DateTime.now(); // read after loading, so "1h ago" isn't "59m ago"
        final items = snap.data;
        if (snap.hasError) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.screen),
            child: Text("Couldn't load notifications."),
          );
        }
        if (items == null) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.section),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('No notifications yet.'),
                if (_hidden > 0) _hiddenNote(),
              ],
            ),
          );
        }
        bool isToday(DateTime t) =>
            t.year == now.year && t.month == now.month && t.day == now.day;
        final today = items.where((n) => isToday(n.time)).toList();
        final earlier = items.where((n) => !isToday(n.time)).toList();
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.lg),
          children: [
            if (items.any((n) => !n.read))
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: () => _markAllRead(items), child: const Text('Mark all as read')),
              ),
            if (today.isNotEmpty) ..._group('Today', today, now),
            if (earlier.isNotEmpty) ..._group('Earlier', earlier, now),
            if (_hidden > 0) _hiddenNote(),
          ],
        );
      }),
    );
  }

  Widget _hiddenNote() => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$_hidden hidden by your notification settings.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.muted),
              ),
            ),
            TextButton(onPressed: _openSettings, child: const Text('Change')),
          ],
        ),
      );

  List<Widget> _group(String label, List<AppNotification> items, DateTime now) {
    final text = Theme.of(context).textTheme;
    return [
      Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
        child: Semantics(
          header: true,
          child: Text(label, style: text.labelMedium?.copyWith(color: AppColors.muted)),
        ),
      ),
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const Divider(height: 1, indent: 52),
        _row(items[i], now),
      ],
    ];
  }

  Widget _row(AppNotification n, DateTime now) {
    final text = Theme.of(context).textTheme;
    return Pressable(
      onTap: () => _open(n),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: AppColors.fill, shape: BoxShape.circle),
              child: Icon(_icon(n.kind), size: 20, color: AppColors.ink),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(n.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: n.read
                      ? text.bodyLarge
                      : text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(formatTimeAgo(n.time, now),
                style: text.bodyMedium?.copyWith(color: AppColors.muted)),
            // Unread marker; the space stays so times line up either way.
            Semantics(
              label: n.read ? null : 'Unread',
              child: AnimatedContainer(
                duration: AppMotion.of(context, AppMotion.fast),
                curve: AppMotion.curve,
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: n.read ? Colors.transparent : AppColors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _icon(NotificationKind k) => switch (k) {
        NotificationKind.announcement => Icons.campaign_outlined,
        NotificationKind.organization => Icons.groups_outlined,
        NotificationKind.schedule => Icons.event_note_outlined,
        NotificationKind.clearance => Icons.fact_check_outlined,
        NotificationKind.attendance => Icons.how_to_reg_outlined,
        NotificationKind.news => Icons.article_outlined,
        NotificationKind.connection => Icons.person_add_alt_1_outlined,
      };
}
