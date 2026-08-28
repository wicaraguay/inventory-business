import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventy_app/features/auth/domain/auth_user.dart';
import 'package:inventy_app/features/auth/presentation/auth_providers.dart';
import 'package:inventy_app/features/sales/domain/sale.dart';
import 'package:inventy_app/features/sales/domain/sale_repository.dart';
import 'package:inventy_app/features/sales/presentation/sales_providers.dart';
import 'package:inventy_app/features/sales/presentation/sales_screen.dart';
import 'package:inventy_app/features/settings/presentation/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeSaleRepository implements SaleRepository {
  final List<Sale> _records;

  const _FakeSaleRepository({List<Sale> records = const []})
      : _records = records;

  @override
  Future<void> registerSale(List<SaleLine> items) async {}

  @override
  Future<SalesReport> report() async => SalesReport(
        records: _records,
        summary: const SalesSummary(
          count: 3,
          totalAll: 300,
          totalToday: 100,
          totalWeek: 200,
          totalMonth: 300,
          totalQuarter: 300,
          totalYear: 300,
          profitToday: 10,
          profitWeek: 20,
          profitMonth: 30,
          profitQuarter: 30,
          profitYear: 30,
        ),
      );

  @override
  Future<void> voidSale(String id) async {}

  @override
  Future<List<SalesBucket>> series(String by) async => [];

  @override
  Future<List<SalesBucket>> seriesRange(DateTime from, DateTime to) async => [];

  @override
  Future<List<Sale>> recordsInRange(DateTime from, DateTime to) async =>
      _records;
}

// ---------------------------------------------------------------------------
// Stubs
// ---------------------------------------------------------------------------

const _owner = AuthUser(
  id: 'o1',
  username: 'nina',
  role: 'owner',
  displayName: 'Nina',
);

/// Two active sales used in widget tests.
final _fakeSales = [
  Sale(
    id: 's1',
    productName: 'Botín de cuero',
    sku: 'BOT-40',
    quantity: 1,
    unitPrice: 120,
    total: 120,
    createdAt: DateTime(2026, 8, 1, 10),
  ),
  Sale(
    id: 's2',
    productName: 'Zapatilla blanca',
    sku: 'ZAP-38',
    quantity: 2,
    unitPrice: 80,
    total: 160,
    createdAt: DateTime(2026, 8, 2, 15),
  ),
];

/// Helper: pump SalesScreen with given repo overrides.
Future<void> _pumpSalesScreen(
  WidgetTester tester, {
  required List<Sale> records,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final fakeRepo = _FakeSaleRepository(records: records);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        saleRepositoryProvider.overrideWithValue(fakeRepo),
        currentUserProvider.overrideWithValue(_owner),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SalesScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SalesScreen — filtro Desde–Hasta', () {
    testWidgets('muestra las ventas del rango en la tabla', (tester) async {
      await _pumpSalesScreen(tester, records: _fakeSales);

      // Both product names should appear in the table.
      expect(find.textContaining('Botín de cuero'), findsOneWidget);
      expect(find.textContaining('Zapatilla blanca'), findsOneWidget);
    });

    testWidgets('muestra el resumen de período con cantidad y total correcto',
        (tester) async {
      await _pumpSalesScreen(tester, records: _fakeSales);

      // Active sales: 2, total: $280.00
      expect(find.textContaining('2 ventas'), findsOneWidget);
      expect(find.textContaining('\$280.00'), findsOneWidget);
    });

    testWidgets('muestra las métricas globales del salesReportProvider',
        (tester) async {
      await _pumpSalesScreen(tester, records: _fakeSales);

      // MetricCard renders labels uppercased.
      expect(find.text('VENDIDO HOY'), findsOneWidget);
      expect(find.text('TOTAL GENERAL'), findsOneWidget);
    });

    testWidgets('muestra un solo chip compacto de rango de fechas',
        (tester) async {
      await _pumpSalesScreen(tester, records: _fakeSales);

      // Un único control (chip) con el ícono de rango, en vez de dos botones.
      expect(find.byType(ActionChip), findsOneWidget);
      expect(find.byIcon(Icons.date_range), findsOneWidget);
    });

    testWidgets('muestra empty state cuando el rango no tiene ventas',
        (tester) async {
      await _pumpSalesScreen(tester, records: []);

      expect(find.text('No hay ventas en este período'), findsOneWidget);
    });

    testWidgets('el botón Nueva venta está presente', (tester) async {
      await _pumpSalesScreen(tester, records: _fakeSales);

      expect(find.text('Nueva venta'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Unit test: salesInRangeProvider delegates to recordsInRange
  // -------------------------------------------------------------------------

  group('salesInRangeProvider — unit', () {
    test('retorna los registros provistos por el repositorio', () async {
      final container = ProviderContainer(
        overrides: [
          saleRepositoryProvider
              .overrideWithValue(_FakeSaleRepository(records: _fakeSales)),
        ],
      );
      addTearDown(container.dispose);

      final from = DateTime(2026, 8, 1);
      final to = DateTime(2026, 8, 2);
      final result = await container.read(
        salesInRangeProvider((from: from, to: to)).future,
      );

      expect(result.length, 2);
      expect(result[0].productName, 'Botín de cuero');
      expect(result[1].productName, 'Zapatilla blanca');
    });

    test('rango sin ventas devuelve lista vacía', () async {
      final container = ProviderContainer(
        overrides: [
          saleRepositoryProvider
              .overrideWithValue(const _FakeSaleRepository(records: [])),
        ],
      );
      addTearDown(container.dispose);

      final from = DateTime(2026, 8, 1);
      final to = DateTime(2026, 8, 1);
      final result = await container.read(
        salesInRangeProvider((from: from, to: to)).future,
      );

      expect(result, isEmpty);
    });

    test('la suma del total activo es correcta', () async {
      final container = ProviderContainer(
        overrides: [
          saleRepositoryProvider
              .overrideWithValue(_FakeSaleRepository(records: _fakeSales)),
        ],
      );
      addTearDown(container.dispose);

      final from = DateTime(2026, 8, 1);
      final to = DateTime(2026, 8, 2);
      final result = await container.read(
        salesInRangeProvider((from: from, to: to)).future,
      );

      final total = result
          .where((s) => !s.isVoided)
          .fold<double>(0, (sum, s) => sum + s.total);
      expect(total, 280.0); // 120 + 160
    });
  });
}
