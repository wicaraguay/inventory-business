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

  const marks = ['LBR-day13', 'LBR-day14', 'LBR-day20', 'LBR-pag'];

  Future<void> cleanup() async {
    await db.execute(
      Sql.named('DELETE FROM sales WHERE description = ANY(@m)'),
      parameters: {'m': marks},
    );
  }

  setUpAll(() async {
    db = await _connect();
    salesRepo = PostgresSalesRepository(db);
    await cleanup();
    // Three back-dated quick sales on distinct days (noon UTC = same UTC date).
    await salesRepo.register([
      SaleItem(
        quantity: 1,
        unitPrice: 10,
        total: 10,
        description: 'LBR-day13',
        createdAt: DateTime.utc(2025, 6, 13, 12),
      ),
    ]);
    await salesRepo.register([
      SaleItem(
        quantity: 1,
        unitPrice: 20,
        total: 20,
        description: 'LBR-day14',
        createdAt: DateTime.utc(2025, 6, 14, 12),
      ),
    ]);
    await salesRepo.register([
      SaleItem(
        quantity: 1,
        unitPrice: 30,
        total: 30,
        description: 'LBR-day20',
        createdAt: DateTime.utc(2025, 6, 20, 12),
      ),
    ]);
    // Three sales on ONE unique day (2025-07-05) for pagination tests.
    for (var i = 0; i < 3; i++) {
      await salesRepo.register([
        SaleItem(
          quantity: 1,
          unitPrice: 5,
          total: 5,
          description: 'LBR-pag',
          createdAt: DateTime.utc(2025, 7, 5, 12).add(Duration(minutes: i)),
        ),
      ]);
    }
  });

  tearDownAll(() async {
    await cleanup();
    await db.close();
  });

  group('listByRange integration', () {
    test('devuelve solo las ventas dentro del rango [13..14]', () async {
      final rows = await salesRepo.listByRange(
        from: DateTime.utc(2025, 6, 13),
        to: DateTime.utc(2025, 6, 14),
      );
      final descs = rows.map((r) => r.description).toSet();
      expect(descs, contains('LBR-day13'));
      expect(descs, contains('LBR-day14'));
      expect(descs, isNot(contains('LBR-day20')));
    });

    test('un solo día trae solo esa venta', () async {
      final rows = await salesRepo.listByRange(
        from: DateTime.utc(2025, 6, 14),
        to: DateTime.utc(2025, 6, 14),
      );
      final mine = rows.where((r) => marks.contains(r.description)).toList();
      expect(mine.length, 1);
      expect(mine.first.description, 'LBR-day14');
    });

    test('paginación: limit/offset y countByRange', () async {
      final day = DateTime.utc(2025, 7, 5);

      final total = await salesRepo.countByRange(from: day, to: day);
      expect(total, 3);

      final page1 = await salesRepo.listByRange(
        from: day,
        to: day,
        limit: 2,
        offset: 0,
      );
      expect(page1.length, 2);

      final page2 = await salesRepo.listByRange(
        from: day,
        to: day,
        limit: 2,
        offset: 2,
      );
      expect(page2.length, 1);

      // No overlap between pages.
      final ids1 = page1.map((r) => r.id).toSet();
      final ids2 = page2.map((r) => r.id).toSet();
      expect(ids1.intersection(ids2), isEmpty);
    });
  });
}
