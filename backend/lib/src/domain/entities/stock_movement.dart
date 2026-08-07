import 'package:inventy_backend/src/domain/entities/movement_type.dart';

/// A single change to a product's stock. Stock itself is never stored;
/// it is derived from the sum of these movements (see product_stock view).
class StockMovement {
  StockMovement({
    required this.productId,
    required this.quantity,
    required this.type,
    this.note,
  });

  final String productId;
  final int quantity;
  final MovementType type;
  final String? note;
}
