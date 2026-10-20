import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Round photo, or the person's initials when there is no photo.
class UserAvatar extends StatelessWidget {
  final String name;
  final String? imageAsset;
  final double size;

  const UserAvatar({super.key, required this.name, this.imageAsset, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    return Semantics(
      label: name,
      image: true,
      excludeSemantics: true,
      child: ClipOval(
        child: SizedBox.square(
          dimension: size,
          child: imageAsset != null
              ? Image.asset(imageAsset!, fit: BoxFit.cover)
              : ColoredBox(
                  color: AppColors.fill,
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: size * 0.38,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
