import 'package:inventy_backend/src/domain/ports/low_stock_repository.dart';

/// Use case: mark a low-stock alert as read (snooze it for a few days).
class SnoozeLowStock {
  SnoozeLowStock(this._repository);

  final LowStockRepository _repository;

  Future<void> call(String productId) => _repository.snooze(productId);
}
