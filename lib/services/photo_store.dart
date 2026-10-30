import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Photos uploaded in this preview (decided 2026-10-30). They are kept in
/// memory only: never sent anywhere, and gone when the app reloads, like the
/// posts that use them. Posts refer to them as `upload:<n>` next to bundled
/// asset paths, so one list of strings holds both.
class PhotoStore {
  static final _photos = <String, Uint8List>{};
  static var _next = 0;

  static bool isUpload(String path) => path.startsWith('upload:');

  static Uint8List? bytes(String path) => _photos[path];

  /// Keeps [bytes] and returns the path a post can use.
  static String add(Uint8List bytes) {
    final path = 'upload:${++_next}';
    _photos[path] = bytes;
    return path;
  }

  /// Opens the gallery (several at once) or the camera; tests replace it.
  static Future<List<Uint8List>> Function({required int limit, required bool camera}) picker =
      _pickWithImagePicker;

  /// Lets the user pick up to [limit] photos and keeps them. Returns their
  /// paths; empty when they cancelled.
  static Future<List<String>> pick({required int limit, bool camera = false}) async {
    final picked = await picker(limit: limit, camera: camera);
    return [for (final b in picked.take(limit)) add(b)];
  }

  static Future<List<Uint8List>> _pickWithImagePicker(
      {required int limit, required bool camera}) async {
    final picker = ImagePicker();
    // Shrunk on the device, so a phone camera's large photos stay light.
    const maxWidth = 1600.0, quality = 85;
    final files = camera || limit == 1
        ? [
            ?await picker.pickImage(
                source: camera ? ImageSource.camera : ImageSource.gallery,
                maxWidth: maxWidth,
                imageQuality: quality),
          ]
        // The picker refuses a limit below 2; one photo uses pickImage above.
        : await picker.pickMultiImage(maxWidth: maxWidth, imageQuality: quality, limit: limit);
    return [for (final f in files) await f.readAsBytes()];
  }
}
