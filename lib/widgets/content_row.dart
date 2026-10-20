import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'user_avatar.dart';

/// A list row: optional thumbnail, a small source line, a title, and a
/// muted meta line (spec §2.1 "Rows, not cards"). Reused for news, posts,
/// and later for events and event history.
class ContentRow extends StatelessWidget {
  final String title;
  final String? source;
  final String? sourceImage;
  final String? meta;
  final String? imageAsset;
  final Widget? pill;
  final VoidCallback? onTap;

  const ContentRow({
    super.key,
    required this.title,
    this.source,
    this.sourceImage,
    this.meta,
    this.imageAsset,
    this.pill,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageAsset != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: Image.asset(imageAsset!, width: 72, height: 72, fit: BoxFit.cover),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (source != null || pill != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        children: [
                          if (sourceImage != null) ...[
                            UserAvatar(name: source ?? '', imageAsset: sourceImage, size: 18),
                            const SizedBox(width: 6),
                          ],
                          if (source != null)
                            Flexible(
                              child: Text(
                                source!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.bodyMedium?.copyWith(color: AppColors.muted),
                              ),
                            ),
                          if (pill != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            pill!,
                          ],
                        ],
                      ),
                    ),
                  Text(title,
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: text.titleMedium),
                  if (meta != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(meta!,
                          style: text.bodyMedium?.copyWith(color: AppColors.muted)),
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
