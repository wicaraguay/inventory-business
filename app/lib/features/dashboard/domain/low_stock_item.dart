/// A low-stock alert row (product at or below its threshold).
class LowStockItem {
  const LowStockItem({
    required this.productId,
    required this.name,
    required this.sku,
    required this.currentStock,
    required this.threshold,
    this.detail,
  });

  factory LowStockItem.fromJson(Map<String, dynamic> json) => LowStockItem(
        productId: json['productId'] as String,
        name: json['name'] as String,
        detail: json['detail'] as String?,
        sku: json['sku'] as String,
        currentStock: json['currentStock'] as int,
        threshold: json['threshold'] as int,
      );

  final String productId;
  final String name;
  final String? detail;
  final String sku;
  final int currentStock;
  final int threshold;
}
