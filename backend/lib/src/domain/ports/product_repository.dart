import 'package:inventy_backend/src/domain/entities/bulk_product_input.dart';
import 'package:inventy_backend/src/domain/entities/model_size.dart';
import 'package:inventy_backend/src/domain/entities/product.dart';
import 'package:inventy_backend/src/domain/entities/product_with_stock.dart';

/// PORT: persistence contract for products (the flat items).
abstract interface class ProductRepository {
  Future<Product> create({
    required String name,
    required String sku,
    required int lowStockThreshold,
    String? detail,
    double? salePrice,
    double? minPrice,
    double? supplierPrice,
  });

  /// Creates many products at once (each with its initial stock), atomically.
  /// All items share one generated model_id (they're sizes of one model).
  Future<List<Product>> createBulk(List<BulkProductInput> items);

  /// Adds more sizes to an EXISTING model: each new product reuses [modelId]
  /// and inherits the model's image (copied from a sibling). Atomic. Throws if
  /// the model doesn't exist or a size's SKU already exists.
  Future<List<Product>> addSizesToModel(
    String modelId,
    List<BulkProductInput> items,
  );

  Future<Product> update({
    required String id,
    required String name,
    required String sku,
    required int lowStockThreshold,
    String? detail,
    double? salePrice,
    double? minPrice,
    double? supplierPrice,
  });

  /// Deletes a product (cascades to its movements and sales).
  Future<void> delete(String id);

  /// Marks products as labeled (QR printed + applied) or back to pending.
  Future<void> markLabeled(List<String> ids, {required bool labeled});

  /// All products, each with its current stock.
  Future<List<ProductWithStock>> listWithStock();

  /// Resolve a scanned code (SKU or barcode) to its product + stock. Null if none.
  Future<ProductWithStock?> findByCode(String code);

  /// Sizes (with stock) of a model — for the "available sizes" on scan.
  Future<List<ModelSize>> modelSizes(String modelId);
}
