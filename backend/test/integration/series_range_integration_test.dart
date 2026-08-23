@Tags(['integration'])
library;

import 'dart:io';

import 'package:inventy_backend/src/domain/entities/sale_item.dart';
import 'package:inventy_backend/src/infrastructure/postgres/postgres_sales_repository.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

Future<Connection> _connect() => Connection.open(
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? 'localhost',
        database: Platform.environment['DB_NAME'] ?? 'inventy',
        username: Platform.environment['DB_USER'] ?? 'inventy',
        password: Platform.environment['DB_PASS'] ??
            Platform.environment['DB_PASSWORD'] ??
            'inventy',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );

void main() {
  late Connection db;
  late PostgresSalesRepository salesRepo;

  // Unique markers so the test can clean up exactly its own rows and stay
  // idempotent across repeated runs (seriesRange sums ALL sales on a day).
  const marks = ['Rango A', 'Rango B', 'Rango C'];

  Future<void> cleanup() async {
    await db.execute(
      Sql.named('DELETE FROM sales WHERE description = ANY(@m)'),
      parameters: {'m': marks},
    );
  }

  setUpAll(() async {
    db = await _connect();
    salesRepo = PostgresSalesRepository(db);
    await cleanup(); // clear leftovers from a previous aborted run
  });

  tearDownAll(() async {
    await cleanup();
    await db.close();
  });

  group('seriesRange integration', () {
    test('devuelve un bucket por día (inclusive) y suma cada día', () async {
      // Three quick sales on two distinct days inside the range.
      final day1 = DateTime(2025, 3, 10, 12);
      final day2 = DateTime(2025, 3, 12, 12);

      await salesRepo.register([
        SaleItem(
          quantity: 1,
          unitPrice: 100,
          total: 100,
          description: 'Rango A',
          createdAt: day1,
        ),
      ]);
      await salesRepo.register([
        SaleItem(
          quantity: 1,
          unitPrice: 50,
          total: 50,
          description: 'Rango B',
          createdAt: day1,
        ),
      ]);
      await salesRepo.register([
        SaleItem(
          quantity: 1,
          unitPrice: 70,
          total: 70,
          description: 'Rango C',
          createdAt: day2,
        ),
      ]);

      final buckets = await salesRepo.seriesRange(
        from: DateTime(2025, 3, 9),
        to: DateTime(2025, 3, 13),
      );

      // 9,10,11,12,13 → 5 inclusive days.
      expect(buckets.length, 5);

      double totalOn(int day) => buckets
          .firstWhere((b) => b.bucket.toLocal().day == day)
          .total;

      expect(totalOn(10), closeTo(150, 0.01)); // 100 + 50
      expect(totalOn(11), closeTo(0, 0.01)); // zero-filled gap
      expect(totalOn(12), closeTo(70, 0.01));
    });

    test('rango de un solo día devuelve un bucket', () async {
      final buckets = await salesRepo.seriesRange(
        from: DateTime(2025, 3, 10),
        to: DateTime(2025, 3, 10),
      );
      expect(buckets.length, 1);
    });
  });
}
