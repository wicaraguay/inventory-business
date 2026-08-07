import 'dart:typed_data';

import 'package:inventy_backend/src/domain/entities/product_image.dart';

/// PORT: persistence contract for the (optional) per-product image.
abstract interface class ProductImageRepository {
  /// The product's image, or null if it has none.
  Future<ProductImage?> find(String productId);

  /// Store (or replace) the product's image.
  Future<void> save(String productId, Uint8List data, String contentType);

  /// Remove the product's image (no-op if it had none).
  Future<void> delete(String productId);
}
