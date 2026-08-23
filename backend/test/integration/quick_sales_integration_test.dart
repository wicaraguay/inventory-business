@Tags(['integration'])
library;

import 'dart:io';

import 'package:inventy_backend/src/domain/entities/sale_item.dart';
import 'package:inventy_backend/src/infrastructure/postgres/postgres_sales_repository.dart';
import 'package:inventy_backend/src/infrastructure/postgres/postgres_stock_repository.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

// Reads DB connection params from environment (Docker Compose sets these).
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
  late PostgresStockRepository stockRepo;

  // Markers so the test cleans up EXACTLY its own rows and never pollutes a
  // shared DB (integration runs against a live Postgres, not a throwaway one).
  const marks = ['Sandalia negra', 'Ojotas genéricas', 'Mocasín pasado'];

  Future<void> cleanup() async {
    await db.execute(
      Sql.named('DELETE FROM sales WHERE description = ANY(@m)'),
      parameters: {'m': marks},
    );
  }

  setUpAll(() async {
    db = await _connect();
    salesRepo = PostgresSalesRepository(db);
    stockRepo = PostgresStockRepository(db);
    await cleanup();
  });

  tearDownAll(() async {
    await cleanup();
    await db.close();
  });

  group('quick sales integration', () {
    test(
        'registrar venta rápida → aparece en recent() y suma en summary()',
        () async {
      // Before
      final summaryBefore = await salesRepo.summary();

      await salesRepo.register([
        SaleItem(
          quantity: 2,
          unitPrice: 1500,
          description: 'Sandalia negra',
          sizeLabel: '38',
        ),
      ]);

      final recent = await salesRepo.recent();
      final summaryAfter = await salesRepo.summary();

      // Should appear in recent()
      final found = recent.firstWhere(
        (r) => r.description == 'Sandalia negra',
        orElse: () => throw StateError('Quick sale not found in recent()'),
      );
      expect(found.sizeLabel, '38');
      expect(found.quantity, 2);
      expect(found.total, closeTo(3000, 0.01));
      // productName should fall back to description
      expect(found.productName, 'Sandalia negra');

      // Should appear in summary totals
      expect(summaryAfter.totalAll, greaterThan(summaryBefore.totalAll));
      expect(summaryAfter.count, greaterThan(summaryBefore.count));
    });

    test('venta rápida NO cambia el stock de ningún producto', () async {
      // Get all products with some stock
      final stocksBefore = <String, int>{};
      final products = await db.execute(
        'SELECT id FROM products LIMIT 5',
      );
      for (final row in products) {
        final pid = row[0].toString();
        stocksBefore[pid] = await stockRepo.currentStock(pid);
      }

      // Register a quick sale
      await salesRepo.register([
        SaleItem(
          quantity: 5,
          unitPrice: 800,
          description: 'Ojotas genéricas',
          sizeLabel: 'M',
        ),
      ]);

      // Stock should be unchanged
      for (final entry in stocksBefore.entries) {
        final stockAfter = await stockRepo.currentStock(entry.key);
        expect(
          stockAfter,
          entry.value,
          reason: 'Stock de ${entry.key} no debería cambiar',
        );
      }
    });

    test('venta rápida con createdAt en el pasado se guarda con esa fecha',
        () async {
      final pastDate = DateTime(2026, 1, 15, 10, 0, 0);

      await salesRepo.register([
        SaleItem(
          quantity: 1,
          unitPrice: 2000,
          description: 'Mocasín pasado',
          createdAt: pastDate,
        ),
      ]);

      final recent = await salesRepo.recent(limit: 200);
      final found = recent.firstWhere(
        (r) => r.description == 'Mocasín pasado',
        orElse: () => throw StateError('Back-dated sale not found'),
      );
      // Date should match (allow a 2-second tolerance for timezone rounding)
      expect(
        found.createdAt.difference(pastDate.toUtc()).abs().inSeconds,
        lessThan(2),
      );
    });
  });
}
