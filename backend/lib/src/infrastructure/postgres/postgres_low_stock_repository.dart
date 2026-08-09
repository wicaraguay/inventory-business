import 'package:inventy_backend/src/domain/entities/low_stock_product.dart';
import 'package:inventy_backend/src/domain/ports/low_stock_repository.dart';
import 'package:postgres/postgres.dart';

/// ADAPTER: reads the low_stock_products view. SQL lives only here.
class PostgresLowStockRepository implements LowStockRepository {
  PostgresLowStockRepository(this._db);

  final Connection _db;

  @override
  Future<List<LowStockProduct>> lowStock() async {
    // Skip products snoozed ("marcado leído") in the last 3 days; after that
    // they reappear if still low.
    final result = await _db.execute('''
      SELECT lsp.product_id, lsp.name, lsp.detail, lsp.sku,
             lsp.current_stock, lsp.low_stock_threshold
      FROM low_stock_products lsp
      LEFT JOIN low_stock_snoozes s ON s.product_id = lsp.product_id
      WHERE s.snoozed_at IS NULL OR s.snoozed_at < now() - interval '3 days'
      ORDER BY lsp.current_stock ASC
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

  @override
  Future<void> snooze(String productId) async {
    await _db.execute(
      Sql.named('''
        INSERT INTO low_stock_snoozes (product_id, snoozed_at)
        VALUES (@id, now())
        ON CONFLICT (product_id) DO UPDATE SET snoozed_at = now()
      '''),
      parameters: {'id': productId},
    );
  }
}
