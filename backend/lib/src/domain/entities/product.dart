/// A sellable item (flat model). Each product is one thing you count —
/// e.g. "Botín de cuero" with detail "talle 40 · negro". Products that are
/// sizes of the same model share a [modelId].
class Product {
  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.lowStockThreshold,
    this.detail,
    this.salePrice,
    this.minPrice,
    this.supplierPrice,
    this.modelId,
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

  /// Cost paid to the supplier. OWNER-ONLY — never serialized for employees.
  final double? supplierPrice;

  /// Groups the sizes of the same model. Null only for legacy rows in memory.
  final String? modelId;
}
