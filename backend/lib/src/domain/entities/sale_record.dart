/// Read model: one registered sale, enriched with product info.
class SaleRecord {
  SaleRecord({
    required this.id,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.createdAt,
    this.detail,
    this.description,
    this.sizeLabel,
    this.voidedAt,
    this.voidedBy,
  });

  final String id;
  final String productName;
  final String? detail;
  final String sku;
  final int quantity;
  final double unitPrice;
  final double total;
  final DateTime createdAt;

  /// Free-text description for quick sales.
  final String? description;

  /// Size label for quick sales.
  final String? sizeLabel;

  /// When/who voided it (null = active).
  final DateTime? voidedAt;
  final String? voidedBy;
}
