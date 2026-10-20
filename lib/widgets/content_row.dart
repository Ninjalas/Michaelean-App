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

  bool get hasThumb => imageAsset != null || placeholderIcon != null;

  /// Rounded square thumbnail; a status pill overlaps its bottom edge (Luma).
  Widget _thumbnail() {
    return SizedBox(
      width: thumbSize,
      height: thumbSize + (pill != null ? AppSpacing.sm : 0), // room for the overhang
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.small),
            child: imageAsset != null
                ? Image.asset(imageAsset!, width: thumbSize, height: thumbSize, fit: BoxFit.cover)
                : Container(
                    width: thumbSize,
                    height: thumbSize,
                    color: AppColors.fill,
                    child: Icon(placeholderIcon, color: AppColors.muted, size: 28),
                  ),
          ),
          if (pill != null)
            Positioned(
              bottom: 0,
              child: ConstrainedBox(
                // May overhang the thumbnail a little so labels like "Participated" stay whole.
                constraints: const BoxConstraints(maxWidth: thumbSize + 2 * AppSpacing.md),
                child: DecoratedBox(
                  // White ring separates the pill from the photo behind it.
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Padding(padding: const EdgeInsets.all(2), child: pill),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final inlinePill = hasThumb ? null : pill; // with a thumbnail, the pill sits on it
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasThumb) ...[
              _thumbnail(),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (source != null || inlinePill != null)
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
                          if (inlinePill != null) ...[
                            if (source != null) const SizedBox(width: AppSpacing.sm),
                            Flexible(child: inlinePill), // long labels shrink instead of overflowing
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
