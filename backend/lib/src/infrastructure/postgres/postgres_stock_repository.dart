import 'package:inventy_backend/src/domain/entities/stock_movement.dart';
import 'package:inventy_backend/src/domain/ports/stock_repository.dart';
import 'package:postgres/postgres.dart';

/// ADAPTER: implements the domain port using Postgres. SQL lives only here.
class PostgresStockRepository implements StockRepository {
  PostgresStockRepository(this._db);

  final Connection _db;

  @override
  Future<void> save(StockMovement movement) async {
    await _db.execute(
      Sql.named('''
        INSERT INTO stock_movements (product_id, quantity, type, note)
        VALUES (@productId, @quantity, @type, @note)
      '''),
      parameters: {
        'productId': movement.productId,
        'quantity': movement.quantity,
        'type': movement.type.name,
        'note': movement.note,
      },
    );
  }

  @override
  Future<int> currentStock(String productId) async {
    final result = await _db.execute(
      Sql.named(
        'SELECT current_stock FROM product_stock WHERE product_id = @productId',
      ),
      parameters: {'productId': productId},
    );
    if (result.isEmpty) return 0;
    return (result.first.first as int?) ?? 0;
  }
}
