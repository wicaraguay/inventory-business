/// One product to create in a bulk "carga por tallas" (one size of a model),
/// together with its initial stock (how many pairs of that size).
class BulkProductInput {
  const BulkProductInput({
    required this.name,
    required this.sku,
    this.detail,
    this.lowStockThreshold = 0,
    this.salePrice,
    this.minPrice,
    this.initialStock = 0,
  });

  final String name;
  final String? detail;
  final String sku;
  final int lowStockThreshold;
  final double? salePrice;
  final double? minPrice;
  final int initialStock;

  Map<String, dynamic> toJson() => {
        'name': name,
        'sku': sku,
        'lowStockThreshold': lowStockThreshold,
        'initialStock': initialStock,
        if (detail != null) 'detail': detail,
        if (salePrice != null) 'salePrice': salePrice,
        if (minPrice != null) 'minPrice': minPrice,
      };
}
