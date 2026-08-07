import 'package:inventy_app/features/products/domain/product.dart';

abstract interface class ScanRepository {
  /// Resolve a scanned QR code (the product's SKU) to its product (with stock).
  /// Null if no product has that code.
  Future<Product?> resolve(String code);
}
