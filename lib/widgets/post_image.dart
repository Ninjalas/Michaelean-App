import 'package:flutter/material.dart';

import '../services/photo_store.dart';
import '../theme/app_theme.dart';

/// A post photo or event cover: a bundled asset, or one uploaded in this preview
/// ([PhotoStore]). An upload that's gone (the app reloaded) shows a plain tile.
class PostImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Alignment alignment;

  const PostImage(this.path,
      {super.key, this.width, this.height, this.fit, this.alignment = Alignment.center});

  @override
  Widget build(BuildContext context) {
    if (!PhotoStore.isUpload(path)) {
      return Image.asset(path, width: width, height: height, fit: fit, alignment: alignment);
    }
    final bytes = PhotoStore.bytes(path);
    if (bytes == null) {
      return Container(
        width: width,
        height: height,
        color: AppColors.fill,
        child: const Icon(Icons.image_outlined, color: AppColors.muted),
      );
    }
    return Image.memory(bytes, width: width, height: height, fit: fit, alignment: alignment);
  }
}
