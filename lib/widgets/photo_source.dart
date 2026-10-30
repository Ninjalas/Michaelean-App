import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/photo_store.dart';

/// Lets the user pick up to [limit] photos for a post or an event cover. On
/// a phone it asks gallery or camera first; elsewhere it opens the file
/// chooser. Returns the picked photos' paths (empty when cancelled); they
/// stay in this preview's memory only ([PhotoStore]).
Future<List<String>> pickPhotos(BuildContext context, {required int limit}) async {
  final phone = defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  var camera = false;
  if (phone) {
    final choice = await showModalBottomSheet<bool>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(c, false),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(c, true),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return const [];
    camera = choice;
  }
  return PhotoStore.pick(limit: limit, camera: camera);
}
