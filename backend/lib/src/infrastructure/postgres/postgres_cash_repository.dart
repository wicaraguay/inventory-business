import 'package:inventy_backend/src/domain/entities/cash_close.dart';
import 'package:inventy_backend/src/domain/ports/cash_repository.dart';
import 'package:postgres/postgres.dart';

/// ADAPTER: cash closes on Postgres.
class PostgresCashRepository implements CashRepository {
  PostgresCashRepository(this._db);

  final Connection _db;

  static const _cols = 'id, opening_float::float8, sales_total::float8, '
      'counted::float8, difference::float8, closed_by, closed_at';

  @override
  Future<CashClose> save({
    required double openingFloat,
    required double salesTotal,
    required double counted,
    required double difference,
    String? closedBy,
  }) async {
    final result = await _db.execute(
      Sql.named('''
        INSERT INTO cash_closes
          (opening_float, sales_total, counted, difference, closed_by)
        VALUES (@opening, @sales, @counted, @diff, @by)
        RETURNING $_cols
      '''),
      parameters: {
        'opening': openingFloat,
        'sales': salesTotal,
        'counted': counted,
        'diff': difference,
        'by': closedBy,
      },
    );
    return _map(result.first);
  }

  @override
  Future<List<CashClose>> recent({int limit = 30}) async {
    final result = await _db.execute(
      Sql.named(
        'SELECT $_cols FROM cash_closes ORDER BY closed_at DESC LIMIT @lim',
      ),
      parameters: {'lim': limit},
    );
    return result.map(_map).toList();
  }

  CashClose _map(ResultRow row) => CashClose(
        id: row[0].toString(),
        openingFloat: row[1]! as double,
        salesTotal: row[2]! as double,
        counted: row[3]! as double,
        difference: row[4]! as double,
        closedBy: row[5] as String?,
        closedAt: row[6]! as DateTime,
      );
}
