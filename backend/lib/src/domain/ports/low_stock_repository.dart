import 'package:inventy_backend/src/domain/entities/low_stock_product.dart';

/// PORT (segregated): the low-stock feature. Reads current alerts and lets the
/// owner snooze one (marks it read; it reappears in a few days if still low).
abstract interface class LowStockRepository {
  Future<List<LowStockProduct>> lowStock();

  /// Hide a product's alert for a few days.
  Future<void> snooze(String productId);
}
