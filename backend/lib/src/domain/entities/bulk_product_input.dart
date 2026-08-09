/// One product to create in a bulk import (e.g. one size of a model),
/// with its initial stock. All items of one bulk load share a model + prices.
class BulkProductInput {
  BulkProductInput({
    required this.name,
    required this.sku,
    this.detail,
    this.lowStockThreshold = 0,
    this.salePrice,
    this.minPrice,
    this.supplierPrice,
    this.initialStock = 0,
  });

  final String name;
  final String? detail;
  final String sku;
  final int lowStockThreshold;
  final double? salePrice;
  final double? minPrice;
  final double? supplierPrice;
  final int initialStock;
}
