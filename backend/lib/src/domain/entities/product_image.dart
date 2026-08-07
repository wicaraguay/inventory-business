import 'dart:typed_data';

/// A product's stored image: raw (already-compressed) bytes + its MIME type.
class ProductImage {
  ProductImage({required this.data, required this.contentType});

  final Uint8List data;
  final String contentType;
}
