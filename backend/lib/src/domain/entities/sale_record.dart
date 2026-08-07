/// Read model: one registered sale, enriched with product info.
class SaleRecord {
  SaleRecord({
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.createdAt,
    this.detail,
  });

  final String productName;
  final String? detail;
  final String sku;
  final int quantity;
  final double unitPrice;
  final double total;
  final DateTime createdAt;
}
