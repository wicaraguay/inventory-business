import 'package:inventy_backend/src/domain/entities/low_stock_product.dart';
import 'package:inventy_backend/src/domain/ports/low_stock_repository.dart';

/// Use case: list products at or below their threshold.
class DetectLowStock {
  DetectLowStock(this._repository);

  final LowStockRepository _repository;

  Future<List<LowStockProduct>> call() => _repository.lowStock();
}
