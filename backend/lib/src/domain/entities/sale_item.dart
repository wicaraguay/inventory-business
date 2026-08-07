/// One line of a sale: a product, a quantity, and the agreed unit price.
class SaleItem {
  SaleItem({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  final String productId;
  final int quantity;
  final double unitPrice;
}
