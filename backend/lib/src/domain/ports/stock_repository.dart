import 'package:inventy_backend/src/domain/entities/stock_movement.dart';

/// PORT: the domain's contract for persisting/reading stock.
abstract interface class StockRepository {
  Future<void> save(StockMovement movement);

  /// Current stock for a product = sum(entries) - sum(exits).
  Future<int> currentStock(String productId);
}
