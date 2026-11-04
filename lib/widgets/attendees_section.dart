import 'package:flutter/material.dart';

import '../models/guest.dart';
import '../theme/app_theme.dart';
import 'section_header.dart';
import 'user_avatar.dart';

/// The "Attendees" section of an event detail (spec §7.3): overlapping
/// avatars and a count. Anyone who can see the event sees this; the full
/// list behind [onOpen] is for registered guests and managers only.
class AttendeesSection extends StatelessWidget {
  static const _avatar = 40.0;
  static const _step = 28.0; // how far each avatar sits from the previous one

  final GuestSummary summary;
  final VoidCallback onOpen;

  const AttendeesSection({super.key, required this.summary, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final shown = summary.preview.length;
    final going = summary.capacity == null
        ? '${summary.count} going'
        : '${summary.count} of ${summary.capacity} going';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader('Attendees', onSeeAll: onOpen),
        if (summary.count == 0)
          Text('No one has registered yet.',
              style: text.bodyLarge?.copyWith(color: AppColors.muted))
        else
          InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(AppRadius.small),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: (shown - 1) * _step + _avatar,
                    height: _avatar,
                    child: Stack(
                      children: [
                        for (var i = 0; i < shown; i++)
                          Positioned(
                            left: i * _step,
                            child: DecoratedBox(
                              // White ring keeps overlapping avatars apart.
                              decoration: const BoxDecoration(
                                  color: AppColors.white, shape: BoxShape.circle),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: UserAvatar(
                                  name: summary.preview[i].name,
                                  imageAsset: summary.preview[i].photoAsset,
                                  size: _avatar - 4,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(going, style: text.titleMedium)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
