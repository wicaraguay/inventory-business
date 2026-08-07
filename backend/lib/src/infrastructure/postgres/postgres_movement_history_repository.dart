import 'package:inventy_backend/src/domain/entities/movement_record.dart';
import 'package:inventy_backend/src/domain/entities/movement_type.dart';
import 'package:inventy_backend/src/domain/ports/movement_history_repository.dart';
import 'package:postgres/postgres.dart';

/// ADAPTER: reads the movement history from Postgres. SQL lives only here.
class PostgresMovementHistoryRepository implements MovementHistoryRepository {
  PostgresMovementHistoryRepository(this._db);

  final Connection _db;

  @override
  Future<List<MovementRecord>> recent({int limit = 100}) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT p.name, p.detail, p.sku, m.type, m.quantity, m.note, m.created_at
        FROM stock_movements m
        JOIN products p ON p.id = m.product_id
        ORDER BY m.created_at DESC
        LIMIT @limit
      '''),
      parameters: {'limit': limit},
    );

    return result
        .map(
          (row) => MovementRecord(
            productName: row[0]! as String,
            detail: row[1] as String?,
            sku: row[2]! as String,
            type: (row[3]! as String) == 'entry'
                ? MovementType.entry
                : MovementType.exit,
            quantity: row[4]! as int,
            note: row[5] as String?,
            createdAt: row[6]! as DateTime,
          ),
        )
        .toList();
  }
}
