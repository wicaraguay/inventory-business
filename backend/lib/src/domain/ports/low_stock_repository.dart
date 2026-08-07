import 'package:inventy_backend/src/domain/entities/low_stock_product.dart';

/// PORT (segregated): only what the low-stock feature needs to READ.
abstract interface class LowStockRepository {
  Future<List<LowStockProduct>> lowStock();
}
