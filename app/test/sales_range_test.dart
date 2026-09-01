import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventy_app/features/auth/domain/auth_user.dart';
import 'package:inventy_app/features/auth/presentation/auth_providers.dart';
import 'package:inventy_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:inventy_app/features/sales/domain/sale.dart';
import 'package:inventy_app/features/sales/domain/sale_repository.dart';
import 'package:inventy_app/features/sales/presentation/sales_providers.dart';
import 'package:inventy_app/features/settings/presentation/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeSaleRepository implements SaleRepository {
  final List<SalesBucket> _rangeBuckets;

  _FakeSaleRepository({List<SalesBucket>? rangeBuckets})
      : _rangeBuckets = rangeBuckets ?? [];

  @override
  Future<void> registerSale(List<SaleLine> items) async {}

  @override
  Future<SalesReport> report() async => SalesReport(
        records: [],
        summary: const SalesSummary(
          count: 0,
          totalAll: 0,
          totalToday: 0,
          totalWeek: 0,
          totalMonth: 0,
          totalQuarter: 0,
          totalYear: 0,
          profitToday: 0,
          profitWeek: 0,
          profitMonth: 0,
          profitQuarter: 0,
          profitYear: 0,
        ),
      );

  @override
  Future<void> voidSale(String id) async {}

  @override
  Future<List<SalesBucket>> series(String by) async => [];

  @override
  Future<List<SalesBucket>> seriesRange(DateTime from, DateTime to) async =>
      _rangeBuckets;

  @override
  Future<List<Sale>> recordsInRange(DateTime from, DateTime to) async => [];

  @override
  Future<({List<Sale> records, int total})> salesPage({
    required DateTime from,
    required DateTime to,
    required int limit,
    required int offset,
  }) async =>
      (records: <Sale>[], total: 0);
}

// ---------------------------------------------------------------------------
// Shared owner stub
// ---------------------------------------------------------------------------

const _owner = AuthUser(
  id: 'o1',
  username: 'nina',
  role: 'owner',
  displayName: 'Nina',
);

// ---------------------------------------------------------------------------
// Unit tests — seriesRange via ProviderContainer
// ---------------------------------------------------------------------------

void main() {
  group('seriesRange — unit', () {
    test('retorna los buckets provistos por el repositorio', () async {
      final buckets = [
        SalesBucket(bucket: DateTime(2026, 8, 1), total: 100),
        SalesBucket(bucket: DateTime(2026, 8, 2), total: 50),
      ];
      final container = ProviderContainer(
        overrides: [
          saleRepositoryProvider
              .overrideWithValue(_FakeSaleRepository(rangeBuckets: buckets)),
        ],
      );
      addTearDown(container.dispose);

      final from = DateTime(2026, 8, 1);
      final to = DateTime(2026, 8, 2);
      final result = await container.read(
        salesRangeProvider((from: from, to: to)).future,
      );

      expect(result.length, 2);
      expect(result[0].total, 100);
      expect(result[1].total, 50);
    });

    test('la suma del fold es correcta', () async {
      final buckets = [
        SalesBucket(bucket: DateTime(2026, 8, 1), total: 100),
        SalesBucket(bucket: DateTime(2026, 8, 2), total: 50),
        SalesBucket(bucket: DateTime(2026, 8, 3), total: 25),
      ];
      final container = ProviderContainer(
        overrides: [
          saleRepositoryProvider
              .overrideWithValue(_FakeSaleRepository(rangeBuckets: buckets)),
        ],
      );
      addTearDown(container.dispose);

      final from = DateTime(2026, 8, 1);
      final to = DateTime(2026, 8, 3);
      final result = await container.read(
        salesRangeProvider((from: from, to: to)).future,
      );

      final total = result.fold<double>(0, (sum, b) => sum + b.total);
      expect(total, 175.0);
    });

    test('rango vacío devuelve lista vacía y suma cero', () async {
      final container = ProviderContainer(
        overrides: [
          saleRepositoryProvider
              .overrideWithValue(_FakeSaleRepository(rangeBuckets: [])),
        ],
      );
      addTearDown(container.dispose);

      final from = DateTime(2026, 8, 1);
      final to = DateTime(2026, 8, 1);
      final result = await container.read(
        salesRangeProvider((from: from, to: to)).future,
      );

      expect(result, isEmpty);
      final total = result.fold<double>(0, (sum, b) => sum + b.total);
      expect(total, 0.0);
    });
  });

  // -------------------------------------------------------------------------
  // Widget test — DashboardScreen muestra "Total del período"
  // -------------------------------------------------------------------------

  group('DashboardScreen — Ventas por período', () {
    testWidgets('muestra el total del período correctamente', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            salesRangeProvider.overrideWith((ref, r) async => [
                  SalesBucket(bucket: DateTime(2026, 8, 1), total: 100),
                  SalesBucket(bucket: DateTime(2026, 8, 2), total: 50),
                ]),
            salesReportProvider.overrideWith((ref) async => SalesReport(
                  records: [],
                  summary: const SalesSummary(
                    count: 0,
                    totalAll: 0,
                    totalToday: 0,
                    totalWeek: 0,
                    totalMonth: 0,
                    totalQuarter: 0,
                    totalYear: 0,
                    profitToday: 0,
                    profitWeek: 0,
                    profitMonth: 0,
                    profitQuarter: 0,
                    profitYear: 0,
                  ),
                )),
            salesSeriesProvider.overrideWith((ref, by) async => []),
            currentUserProvider.overrideWithValue(_owner),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DashboardScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Total del período:'), findsOneWidget);
      expect(find.textContaining('\$150.00'), findsOneWidget);
    });
  });
}
