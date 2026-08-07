import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Compresses an image before upload: downscale so the longest side is at most
/// [maxDimension] px, then re-encode as JPEG at [quality]. A ~4MB phone photo
/// drops to ~100-150KB. Pure Dart, so it runs the same on web and Android.
///
/// If the bytes can't be decoded (unknown format), the original is returned.
Future<Uint8List> compressImage(
  Uint8List input, {
  int maxDimension = 1000,
  int quality = 75,
}) async {
  final decoded = img.decodeImage(input);
  if (decoded == null) return input;

  var out = decoded;
  final longest =
      decoded.width > decoded.height ? decoded.width : decoded.height;
  if (longest > maxDimension) {
    out = decoded.width >= decoded.height
        ? img.copyResize(decoded, width: maxDimension)
        : img.copyResize(decoded, height: maxDimension);
  }
  return Uint8List.fromList(img.encodeJpg(out, quality: quality));
}
