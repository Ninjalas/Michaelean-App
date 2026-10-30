import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'post_image.dart';

/// A post's photos: one shows at its own shape; several swipe sideways, with
/// a "1/2" counter and dots, like a Facebook post with more than one photo.
class PhotoCarousel extends StatefulWidget {
  final List<String> images;

  const PhotoCarousel(this.images, {super.key});

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final radius = BorderRadius.circular(AppRadius.large);
    if (images.length == 1) {
      return ClipRRect(
        borderRadius: radius,
        child: PostImage(images.first, width: double.infinity),
      );
    }
    return Column(
      children: [
        ClipRRect(
          borderRadius: radius,
          child: AspectRatio(
            aspectRatio: 6 / 5, // the school's post graphics are about this shape
            child: Stack(
              children: [
                PageView(
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    for (var i = 0; i < images.length; i++)
                      Semantics(
                        label: 'Photo ${i + 1} of ${images.length}',
                        image: true,
                        child: PostImage(images[i], fit: BoxFit.cover),
                      ),
                  ],
                ),
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text('${_page + 1}/${images.length}',
                        style: const TextStyle(
                            color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < images.length; i++)
                AnimatedContainer(
                  duration: AppMotion.of(context, AppMotion.fast),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page ? AppColors.navy : AppColors.track,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
