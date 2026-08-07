import 'package:inventy_backend/src/domain/entities/product.dart';

/// Read model: a product with its current derived stock and image info.
class ProductWithStock {
  ProductWithStock({
    required this.product,
    required this.currentStock,
    this.hasImage = false,
    this.imageVersion = 0,
  });

  final Product product;
  final int currentStock;

  /// Whether this product has an uploaded image.
  final bool hasImage;

  /// Epoch seconds of the last image change — used to cache-bust the image URL.
  final int imageVersion;
}
