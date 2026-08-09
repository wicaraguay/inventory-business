/// One size of a model, with its current stock — used to show "available sizes"
/// when scanning a product at the register.
class ModelSize {
  ModelSize({
    required this.productId,
    required this.label,
    required this.currentStock,
  });

  final String productId;

  /// Human size label (the product's detail, e.g. "talle 40").
  final String label;
  final int currentStock;
}
