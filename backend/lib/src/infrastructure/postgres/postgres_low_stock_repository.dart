import 'package:inventy_backend/src/domain/entities/low_stock_product.dart';
import 'package:inventy_backend/src/domain/ports/low_stock_repository.dart';
import 'package:postgres/postgres.dart';

/// ADAPTER: reads the low_stock_products view. SQL lives only here.
class PostgresLowStockRepository implements LowStockRepository {
  PostgresLowStockRepository(this._db);

  final Connection _db;

  @override
  Future<List<LowStockProduct>> lowStock() async {
    final result = await _db.execute('''
      SELECT product_id, name, detail, sku, current_stock, low_stock_threshold
      FROM low_stock_products
      ORDER BY current_stock ASC
    ''');

    return result
        .map(
          (row) => LowStockProduct(
            productId: row[0].toString(),
            name: row[1]! as String,
            detail: row[2] as String?,
            sku: row[3]! as String,
            currentStock: row[4]! as int,
            threshold: row[5]! as int,
          ),
        )
        .toList();
  }
}
