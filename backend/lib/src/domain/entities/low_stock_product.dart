/// A product at or below its threshold, for the low-stock alerts.
class LowStockProduct {
  LowStockProduct({
    required this.productId,
    required this.name,
    required this.sku,
    required this.currentStock,
    required this.threshold,
    this.detail,
  });

  final String productId;
  final String name;
  final String? detail;
  final String sku;
  final int currentStock;
  final int threshold;
}
