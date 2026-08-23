/// One line of a sale.
/// Quick sale: productId is null/empty → does NOT affect stock.
class SaleItem {
  SaleItem({
    this.productId,
    required this.quantity,
    required this.unitPrice,
    this.total,
    this.description,
    this.sizeLabel,
    this.createdAt,
  });

  /// Null or empty means a quick sale (no product in inventory).
  final String? productId;
  final int quantity;
  final double unitPrice;

  /// Exact line total actually charged. When set, it is stored as-is instead of
  /// deriving `quantity * unitPrice` — avoids sub-cent rounding on quick sales
  /// where the seller types the total (e.g. 3 pairs for $50). Falls back to
  /// `quantity * unitPrice` when null.
  final double? total;

  /// Required for quick sales. Free-text description (e.g. "Sandalias negras").
  final String? description;

  /// Optional size label (e.g. "38", "M").
  final String? sizeLabel;

  /// If set, overrides the default created_at (for back-dating entries).
  final DateTime? createdAt;

  /// True when this item has no product in the inventory.
  bool get isQuickSale => productId == null || productId!.trim().isEmpty;
}
