import 'package:inventy_backend/src/domain/entities/bulk_product_input.dart';
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
  });

  /// Creates many products at once (each with its initial stock), atomically.
  Future<List<Product>> createBulk(List<BulkProductInput> items);

  Future<Product> update({
    required String id,
    required String name,
    required String sku,
    required int lowStockThreshold,
    String? detail,
    double? salePrice,
    double? minPrice,
  });

  /// Deletes a product (cascades to its movements and sales).
  Future<void> delete(String id);

  /// All products, each with its current stock.
  Future<List<ProductWithStock>> listWithStock();

  /// Resolve a scanned code (SKU or barcode) to its product + stock. Null if none.
  Future<ProductWithStock?> findByCode(String code);
}
