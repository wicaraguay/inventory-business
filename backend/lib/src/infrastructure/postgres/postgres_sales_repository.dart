import 'package:inventy_backend/src/domain/entities/sale_item.dart';
import 'package:inventy_backend/src/domain/entities/sale_record.dart';
import 'package:inventy_backend/src/domain/entities/sales_bucket.dart';
import 'package:inventy_backend/src/domain/entities/sales_summary.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';
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
        SELECT s.id, p.name, p.detail, p.sku, s.quantity,
               s.unit_price::float8, s.total::float8, s.created_at,
               s.voided_at, s.voided_by
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
            id: row[0].toString(),
            productName: row[1]! as String,
            detail: row[2] as String?,
            sku: row[3]! as String,
            quantity: row[4]! as int,
            unitPrice: row[5]! as double,
            total: row[6]! as double,
            createdAt: row[7]! as DateTime,
            voidedAt: row[8] as DateTime?,
            voidedBy: row[9] as String?,
          ),
        )
        .toList();
  }

  @override
  Future<void> voidSale(String id, String? by) async {
    await _db.runTx((tx) async {
      final res = await tx.execute(
        Sql.named(
          'SELECT product_id, quantity, voided_at FROM sales WHERE id = @id',
        ),
        parameters: {'id': id},
      );
      if (res.isEmpty) throw DomainException('La venta no existe');
      final row = res.first;
      if (row[2] != null) throw DomainException('La venta ya está anulada');
      final productId = row[0].toString();
      final quantity = row[1]! as int;
      await tx.execute(
        Sql.named(
          'UPDATE sales SET voided_at = now(), voided_by = @by WHERE id = @id',
        ),
        parameters: {'id': id, 'by': by},
      );
      // Compensating entry movement restores the stock the sale had taken.
      await tx.execute(
        Sql.named('''
          INSERT INTO stock_movements (product_id, quantity, type, note)
          VALUES (@p, @q, 'entry', 'Anulación de venta')
        '''),
        parameters: {'p': productId, 'q': quantity},
      );
    });
  }

  @override
  Future<SalesSummary> summary() async {
    // Revenue = SUM(total). Estimated profit = SUM((price - cost) * qty), with
    // the product's CURRENT supplier price as cost (unknown cost counts as 0).
    // "Week" is the last 7 calendar days (today + previous 6). Voided excluded.
    const profit = '(s.unit_price - COALESCE(p.supplier_price, 0)) * s.quantity';
    final result = await _db.execute('''
      SELECT
        COUNT(*)::int,
        COALESCE(SUM(s.total), 0)::float8,
        COALESCE(SUM(s.total) FILTER (WHERE s.created_at::date = current_date), 0)::float8,
        COALESCE(SUM($profit) FILTER (WHERE s.created_at::date = current_date), 0)::float8,
        COALESCE(SUM(s.total) FILTER (WHERE s.created_at >= current_date - interval '6 days'), 0)::float8,
        COALESCE(SUM($profit) FILTER (WHERE s.created_at >= current_date - interval '6 days'), 0)::float8,
        COALESCE(SUM(s.total) FILTER (WHERE date_trunc('month', s.created_at) = date_trunc('month', now())), 0)::float8,
        COALESCE(SUM($profit) FILTER (WHERE date_trunc('month', s.created_at) = date_trunc('month', now())), 0)::float8,
        COALESCE(SUM(s.total) FILTER (WHERE date_trunc('quarter', s.created_at) = date_trunc('quarter', now())), 0)::float8,
        COALESCE(SUM($profit) FILTER (WHERE date_trunc('quarter', s.created_at) = date_trunc('quarter', now())), 0)::float8,
        COALESCE(SUM(s.total) FILTER (WHERE date_trunc('year', s.created_at) = date_trunc('year', now())), 0)::float8,
        COALESCE(SUM($profit) FILTER (WHERE date_trunc('year', s.created_at) = date_trunc('year', now())), 0)::float8
      FROM sales s
      JOIN products p ON p.id = s.product_id
      WHERE s.voided_at IS NULL
    ''');
    final row = result.first;
    return SalesSummary(
      count: row[0]! as int,
      totalAll: row[1]! as double,
      totalToday: row[2]! as double,
      profitToday: row[3]! as double,
      totalWeek: row[4]! as double,
      profitWeek: row[5]! as double,
      totalMonth: row[6]! as double,
      profitMonth: row[7]! as double,
      totalQuarter: row[8]! as double,
      profitQuarter: row[9]! as double,
      totalYear: row[10]! as double,
      profitYear: row[11]! as double,
    );
  }

  @override
  Future<({double total, int count})> todayTotals() async {
    final result = await _db.execute('''
      SELECT COALESCE(SUM(total), 0)::float8, COUNT(*)::int
      FROM sales
      WHERE created_at::date = current_date AND voided_at IS NULL
    ''');
    final row = result.first;
    return (total: row[0]! as double, count: row[1]! as int);
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
                            AND s.voided_at IS NULL
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
                            AND s.voided_at IS NULL
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
