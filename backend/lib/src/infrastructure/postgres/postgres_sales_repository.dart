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
        if (item.createdAt != null) {
          await tx.execute(
            Sql.named('''
              INSERT INTO sales (product_id, quantity, unit_price, total,
                                 description, size_label, created_at)
              VALUES (@productId, @quantity, @unitPrice, @total,
                      @description, @sizeLabel, @createdAt)
            '''),
            parameters: {
              'productId': item.isQuickSale ? null : item.productId,
              'quantity': item.quantity,
              'unitPrice': item.unitPrice,
              'total': item.total ?? item.quantity * item.unitPrice,
              'description': item.description,
              'sizeLabel': item.sizeLabel,
              'createdAt': item.createdAt,
            },
          );
        } else {
          await tx.execute(
            Sql.named('''
              INSERT INTO sales (product_id, quantity, unit_price, total,
                                 description, size_label)
              VALUES (@productId, @quantity, @unitPrice, @total,
                      @description, @sizeLabel)
            '''),
            parameters: {
              'productId': item.isQuickSale ? null : item.productId,
              'quantity': item.quantity,
              'unitPrice': item.unitPrice,
              'total': item.total ?? item.quantity * item.unitPrice,
              'description': item.description,
              'sizeLabel': item.sizeLabel,
            },
          );
        }

        // Exit movement only for inventory items (quick sales don't touch stock).
        if (!item.isQuickSale) {
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
      }
    });
  }

  @override
  Future<List<SaleRecord>> recent({int limit = 100}) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT s.id,
               COALESCE(p.name, s.description, 'Venta rápida') AS product_name,
               COALESCE(p.detail, s.size_label) AS detail,
               COALESCE(p.sku, '—') AS sku,
               s.quantity,
               s.unit_price::float8,
               s.total::float8,
               s.created_at,
               s.voided_at,
               s.voided_by,
               s.description,
               s.size_label
        FROM sales s
        LEFT JOIN products p ON p.id = s.product_id
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
            description: row[10] as String?,
            sizeLabel: row[11] as String?,
          ),
        )
        .toList();
  }

  @override
  Future<List<SaleRecord>> listByRange({
    required DateTime from,
    required DateTime to,
    int limit = 1000,
  }) async {
    // Compare against DATE LITERALS ('YYYY-MM-DD'), not timestamptz params, so
    // the range is unambiguous. `created_at::date` uses the DB session timezone
    // (America/Guayaquil), so the window matches the business's local days.
    String ymd(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    final result = await _db.execute(
      Sql.named('''
        SELECT s.id,
               COALESCE(p.name, s.description, 'Venta rápida') AS product_name,
               COALESCE(p.detail, s.size_label) AS detail,
               COALESCE(p.sku, '—') AS sku,
               s.quantity,
               s.unit_price::float8,
               s.total::float8,
               s.created_at,
               s.voided_at,
               s.voided_by,
               s.description,
               s.size_label
        FROM sales s
        LEFT JOIN products p ON p.id = s.product_id
        WHERE s.created_at::date BETWEEN @from::date AND @to::date
        ORDER BY s.created_at DESC
        LIMIT @limit
      '''),
      parameters: {'from': ymd(from), 'to': ymd(to), 'limit': limit},
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
            description: row[10] as String?,
            sizeLabel: row[11] as String?,
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
      final productId = row[0]?.toString();
      final quantity = row[1]! as int;
      await tx.execute(
        Sql.named(
          'UPDATE sales SET voided_at = now(), voided_by = @by WHERE id = @id',
        ),
        parameters: {'id': id, 'by': by},
      );
      // Restore stock only for inventory sales (not quick sales).
      if (productId != null && productId.isNotEmpty) {
        await tx.execute(
          Sql.named('''
            INSERT INTO stock_movements (product_id, quantity, type, note)
            VALUES (@p, @q, 'entry', 'Anulación de venta')
          '''),
          parameters: {'p': productId, 'q': quantity},
        );
      }
    });
  }

  @override
  Future<SalesSummary> summary() async {
    // Revenue = SUM(total). Estimated profit = SUM((price - cost) * qty), with
    // the product's CURRENT supplier price as cost (unknown cost counts as 0).
    // Quick sales: supplier_price = NULL → COALESCE → 0 → profit = total.
    // "Week" is the last 7 calendar days (today + previous 6). Voided excluded.
    const profit =
        '(s.unit_price - COALESCE(p.supplier_price, 0)) * s.quantity';
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
      LEFT JOIN products p ON p.id = s.product_id
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

  @override
  Future<List<SalesBucket>> seriesRange({
    required DateTime from,
    required DateTime to,
  }) async {
    // One zero-filled bucket per calendar day in [from, to] (inclusive).
    // Params are bound (not interpolated) to avoid injection.
    final result = await _db.execute(
      Sql.named('''
        SELECT g AS bucket, COALESCE(SUM(s.total), 0)::float8 AS total
        FROM generate_series(@from::date, @to::date, interval '1 day') g
        LEFT JOIN sales s ON s.created_at::date = g::date
                          AND s.voided_at IS NULL
        GROUP BY g ORDER BY g
      '''),
      parameters: {'from': from, 'to': to},
    );
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
