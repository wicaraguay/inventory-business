/// A sellable item (flat model). Each product is one thing you count —
/// e.g. "Botín de cuero" with detail "talle 40 · negro". No variants.
class Product {
  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.lowStockThreshold,
    this.detail,
    this.salePrice,
    this.minPrice,
  });

  final String id;
  final String name;
  final String? detail;
  final String sku;
  final int lowStockThreshold;

  /// Normal sale price (list). Null if not set yet.
  final double? salePrice;

  /// Minimum ("último") price you'd sell it for. Null if not set.
  final double? minPrice;
}
