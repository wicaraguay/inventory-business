import 'package:inventy_backend/src/domain/entities/product.dart';

/// Read model: a product with its current derived stock and image info.
class ProductWithStock {
  ProductWithStock({
    required this.product,
    required this.currentStock,
    this.hasImage = false,
    this.imageVersion = 0,
    this.labeled = true,
  });

  final Product product;
  final int currentStock;

  /// Whether this product has an uploaded image.
  final bool hasImage;

  /// Epoch seconds of the last image change — used to cache-bust the image URL.
  final int imageVersion;

  /// Whether the product's QR label has been printed AND applied. New products
  /// start false (pending); the owner marks them done after labeling.
  final bool labeled;
}
