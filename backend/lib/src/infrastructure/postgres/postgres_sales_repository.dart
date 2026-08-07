import 'package:inventy_backend/src/domain/entities/sale_item.dart';
import 'package:inventy_backend/src/domain/entities/sale_record.dart';
import 'package:inventy_backend/src/domain/entities/sales_bucket.dart';
import 'package:inventy_backend/src/domain/entities/sales_summary.dart';
import 'package:inventy_backend/src/domain/ports/sales_repository.dart';
import 'package:postgres/postgres.dart';

/// ADAPTER: sales persistence on Postgres. SQL lives only here.
class PostgresSalesRepository implements SalesRepository {
  PostgresSalesRepository(this._db);

  final Connection _db;

  @override
  Future<void> register(List<SaleItem> items) async {
    await _db.runTx((tx) async {
      for (final item in items) {
        await tx.execute(
          Sql.named('''
            INSERT INTO sales (product_id, quantity, unit_price, total)
            VALUES (@productId, @quantity, @unitPrice, @total)
          '''),
          parameters: {
            'productId': item.productId,
            'quantity': item.quantity,
            'unitPrice': item.unitPrice,
            'total': item.quantity * item.unitPrice,
          },
        );
        // Each sale is also an exit movement so it shows in Movimientos.
        await tx.execute(
          Sql.named('''
            INSERT INTO stock_movements (product_id, quantity, type, note)
            VALUES (@productId, @quantity, 'exit', 'Venta')
          '''),
          parameters: {
            'productId': item.productId,
            'quantity': item.quantity,
          },
        );
      }
    });
  }

  @override
  Future<List<SaleRecord>> recent({int limit = 100}) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT p.name, p.detail, p.sku, s.quantity,
               s.unit_price::float8, s.total::float8, s.created_at
        FROM sales s
        JOIN products p ON p.id = s.product_id
        ORDER BY s.created_at DESC
        LIMIT @limit
      '''),
      parameters: {'limit': limit},
    );

    return result
        .map(
          (row) => SaleRecord(
            productName: row[0]! as String,
            detail: row[1] as String?,
            sku: row[2]! as String,
            quantity: row[3]! as int,
            unitPrice: row[4]! as double,
            total: row[5]! as double,
            createdAt: row[6]! as DateTime,
          ),
        )
        .toList();
  }

  @override
  Future<SalesSummary> summary() async {
    final result = await _db.execute('''
      SELECT
        COUNT(*)::int,
        COALESCE(SUM(total), 0)::float8,
        COALESCE(SUM(total) FILTER (WHERE created_at::date = current_date), 0)::float8,
        COALESCE(SUM(total) FILTER (
          WHERE date_trunc('month', created_at) = date_trunc('month', now())
        ), 0)::float8,
        COALESCE(SUM(total) FILTER (
          WHERE date_trunc('year', created_at) = date_trunc('year', now())
        ), 0)::float8
      FROM sales
    ''');
    final row = result.first;
    return SalesSummary(
      count: row[0]! as int,
      totalAll: row[1]! as double,
      totalToday: row[2]! as double,
      totalMonth: row[3]! as double,
      totalYear: row[4]! as double,
    );
  }

  @override
  Future<List<SalesBucket>> series({
    required String by,
    required int buckets,
  }) async {
    final n = buckets < 1 ? 1 : buckets;
    final sql = by == 'hour'
        ? '''
          SELECT g AS bucket, COALESCE(SUM(s.total), 0)::float8 AS total
          FROM generate_series(
                 date_trunc('hour', now()) - (${n - 1} * interval '1 hour'),
                 date_trunc('hour', now()),
                 interval '1 hour'
               ) g
          LEFT JOIN sales s ON date_trunc('hour', s.created_at) = g
          GROUP BY g ORDER BY g
        '''
        : '''
          SELECT g AS bucket, COALESCE(SUM(s.total), 0)::float8 AS total
          FROM generate_series(
                 current_date - (${n - 1} * interval '1 day'),
                 current_date,
                 interval '1 day'
               ) g
          LEFT JOIN sales s ON s.created_at::date = g::date
          GROUP BY g ORDER BY g
        ''';

    final result = await _db.execute(sql);
    return result
        .map(
          (row) => SalesBucket(
            bucket: row[0]! as DateTime,
            total: row[1]! as double,
          ),
        )
        .toList();
  }
}
