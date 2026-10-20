import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'user_avatar.dart';

/// A list row: optional thumbnail, a small source line, a title, and a
/// muted meta line (spec §2.1 "Rows, not cards"). Reused for news, posts,
/// and later for events and event history.
class ContentRow extends StatelessWidget {
  static const thumbSize = 76.0;

  /// Divider indent that lines a hairline up with the text column of rows
  /// that have a thumbnail (Luma-style).
  static const textIndent = thumbSize + AppSpacing.md;

  final String title;
  final String? source;
  final String? sourceImage;
  final String? meta;
  final IconData? metaIcon; // small gray icon before the meta line
  final String? imageAsset;
  final IconData? placeholderIcon; // gray tile when there's no image, keeps rows aligned
  final Widget? pill;
  final VoidCallback? onTap;

  const ContentRow({
    super.key,
    required this.title,
    this.source,
    this.sourceImage,
    this.meta,
    this.metaIcon,
    this.imageAsset,
    this.placeholderIcon,
    this.pill,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageAsset != null || placeholderIcon != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: imageAsset != null
                    ? Image.asset(imageAsset!,
                        width: thumbSize, height: thumbSize, fit: BoxFit.cover)
                    : Container(
                        width: thumbSize,
                        height: thumbSize,
                        color: AppColors.fill,
                        child: Icon(placeholderIcon, color: AppColors.muted, size: 28),
                      ),
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
                            if (source != null) const SizedBox(width: AppSpacing.sm),
                            Flexible(child: pill!), // long labels shrink instead of overflowing
                          ],
                        ],
                      ),
                    ),
                  Text(title,
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: text.titleMedium),
                  if (meta != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Row(
                        children: [
                          if (metaIcon != null) ...[
                            Icon(metaIcon, size: 16, color: AppColors.muted),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(meta!,
                                style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                          ),
                        ],
                      ),
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
