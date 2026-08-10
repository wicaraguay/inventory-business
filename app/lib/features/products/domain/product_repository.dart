import 'dart:typed_data';

import 'package:inventy_app/features/products/domain/bulk_product_input.dart';
import 'package:inventy_app/features/products/domain/product.dart';

abstract interface class ProductRepository {
  Future<List<Product>> list();

  Future<Product> create({
    required String name,
    required String sku,
    required int lowStockThreshold,
    String? detail,
    double? salePrice,
    double? minPrice,
    double? supplierPrice,
  });

  /// Creates many products at once (all sizes of a model), each with its
  /// initial stock. Returns the created products (with ids) for label printing.
  Future<List<Product>> createBulk(List<BulkProductInput> items);

  /// Adds more sizes to an existing model (same model_id, prices, and image).
  /// Returns the created products for label printing.
  Future<List<Product>> addModelSizes(
    String modelId,
    List<BulkProductInput> items,
  );

  Future<void> update({
    required String id,
    required String name,
    required String sku,
    required int lowStockThreshold,
    String? detail,
    double? salePrice,
    double? minPrice,
    double? supplierPrice,
  });

  Future<void> delete(String id);

  /// Marks products as labeled (QR printed + applied) or back to pending.
  Future<void> markLabeled(List<String> ids, {required bool labeled});

  /// Uploads (or replaces) a product's image with the given (compressed) bytes.
  Future<void> uploadImage(String id, Uint8List bytes);

  /// Removes a product's image.
  Future<void> deleteImage(String id);
}
