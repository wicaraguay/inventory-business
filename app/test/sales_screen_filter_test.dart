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

  @override
  Future<({List<Sale> records, int total})> salesPage({
    required DateTime from,
    required DateTime to,
    required int limit,
    required int offset,
  }) async {
    return (records: _records, total: _records.length);
  }
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
// Tests — month navigator
// ---------------------------------------------------------------------------

void main() {
  group('SalesScreen — navegador de mes', () {
    testWidgets('muestra el mes actual en el navegador', (tester) async {
      await _pumpSalesScreen(tester, records: _fakeSales);

      final now = DateTime.now();
      const months = [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
      ];
      final expectedLabel = '${months[now.month - 1]} ${now.year}';
      expect(find.text(expectedLabel), findsOneWidget);
    });

    testWidgets('la flecha › está deshabilitada en el mes actual',
        (tester) async {
      await _pumpSalesScreen(tester, records: _fakeSales);

      // Find the month-next button by key and confirm onPressed is null.
      final nextBtn = tester.widget<IconButton>(
        find.byKey(const Key('month-next')),
      );
      expect(nextBtn.onPressed, isNull,
          reason: 'El botón › debe estar deshabilitado en el mes actual');
    });

    testWidgets('al tocar ‹ cambia al mes anterior', (tester) async {
      await _pumpSalesScreen(tester, records: _fakeSales);

      final now = DateTime.now();
      final prevMonth = DateTime(now.year, now.month - 1, 1);
      const months = [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
      ];
      final expectedLabel = '${months[prevMonth.month - 1]} ${prevMonth.year}';

      await tester.tap(find.byKey(const Key('month-prev')));
      await tester.pumpAndSettle();

      expect(find.text(expectedLabel), findsOneWidget);
    });

    testWidgets('al volver al mes actual › se deshabilita de nuevo',
        (tester) async {
      await _pumpSalesScreen(tester, records: _fakeSales);

      // Go to prev month.
      await tester.tap(find.byKey(const Key('month-prev')));
      await tester.pumpAndSettle();

      // › should now be enabled (not current month).
      final nextBtnAfterPrev = tester.widget<IconButton>(
        find.byKey(const Key('month-next')),
      );
      expect(nextBtnAfterPrev.onPressed, isNotNull,
          reason: 'El › debe estar habilitado en el mes anterior');

      // Go forward again → back to current month.
      await tester.tap(find.byKey(const Key('month-next')));
      await tester.pumpAndSettle();

      final nextBtnCurrent = tester.widget<IconButton>(
        find.byKey(const Key('month-next')),
      );
      expect(nextBtnCurrent.onPressed, isNull,
          reason: 'El › debe volver a deshabilitarse al estar en el mes actual');
    });

    testWidgets('muestra las ventas del mes en la tabla', (tester) async {
      await _pumpSalesScreen(tester, records: _fakeSales);

      expect(find.textContaining('Botín de cuero'), findsOneWidget);
      expect(find.textContaining('Zapatilla blanca'), findsOneWidget);
    });

    testWidgets('muestra el total de ventas del mes', (tester) async {
      await _pumpSalesScreen(tester, records: _fakeSales);

      // The summary shows "2 ventas en el mes" (total from backend = 2).
      expect(find.textContaining('2 ventas en el mes'), findsOneWidget);
    });

    testWidgets('muestra las métricas globales del salesReportProvider',
        (tester) async {
      await _pumpSalesScreen(tester, records: _fakeSales);

      expect(find.text('VENDIDO HOY'), findsOneWidget);
      expect(find.text('TOTAL GENERAL'), findsOneWidget);
    });

    testWidgets('muestra empty state cuando el mes no tiene ventas',
        (tester) async {
      await _pumpSalesScreen(tester, records: []);

      expect(find.text('No hay ventas en este mes'), findsOneWidget);
    });

    testWidgets('el botón Nueva venta está presente', (tester) async {
      await _pumpSalesScreen(tester, records: _fakeSales);

      expect(find.text('Nueva venta'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Tests — paginación
  // -------------------------------------------------------------------------

  group('SalesScreen — paginación', () {
    testWidgets('con total <= pageSize, Anterior y Siguiente deshabilitados',
        (tester) async {
      // 2 ventas < 20 → sola página
      await _pumpSalesScreen(tester, records: _fakeSales);

      // "Página 1 de 1"
      expect(find.textContaining('Página 1 de 1'), findsOneWidget);

      // Anterior disabled (page == 0) — located by key.
      final anteriorBtn = tester.widget<TextButton>(
        find.byKey(const Key('page-prev')),
      );
      expect(anteriorBtn.onPressed, isNull,
          reason: 'Anterior debe estar deshabilitado en la primera página');

      // Siguiente disabled (page+1 >= totalPages = 1) — located by key.
      final siguienteBtn = tester.widget<TextButton>(
        find.byKey(const Key('page-next')),
      );
      expect(siguienteBtn.onPressed, isNull,
          reason: 'Siguiente debe estar deshabilitado cuando hay una sola página');
    });
  });

  // -------------------------------------------------------------------------
  // Unit test: salesPageProvider delegates to salesPage
  // -------------------------------------------------------------------------

  group('salesPageProvider — unit', () {
    test('retorna los registros y el total provistos por el repositorio',
        () async {
      final container = ProviderContainer(
        overrides: [
          saleRepositoryProvider
              .overrideWithValue(_FakeSaleRepository(records: _fakeSales)),
        ],
      );
      addTearDown(container.dispose);

      final from = DateTime(2026, 8, 1);
      final to = DateTime(2026, 8, 31);
      final result = await container.read(
        salesPageProvider(
          (from: from, to: to, limit: 20, offset: 0),
        ).future,
      );

      expect(result.records.length, 2);
      expect(result.total, 2);
      expect(result.records[0].productName, 'Botín de cuero');
      expect(result.records[1].productName, 'Zapatilla blanca');
    });

    test('rango sin ventas devuelve lista vacía y total 0', () async {
      final container = ProviderContainer(
        overrides: [
          saleRepositoryProvider
              .overrideWithValue(const _FakeSaleRepository(records: [])),
        ],
      );
      addTearDown(container.dispose);

      final from = DateTime(2026, 8, 1);
      final to = DateTime(2026, 8, 31);
      final result = await container.read(
        salesPageProvider(
          (from: from, to: to, limit: 20, offset: 0),
        ).future,
      );

      expect(result.records, isEmpty);
      expect(result.total, 0);
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
      final to = DateTime(2026, 8, 31);
      final result = await container.read(
        salesPageProvider(
          (from: from, to: to, limit: 20, offset: 0),
        ).future,
      );

      final total = result.records
          .where((s) => !s.isVoided)
          .fold<double>(0, (sum, s) => sum + s.total);
      expect(total, 280.0); // 120 + 160
    });

    test('totalPages se calcula correctamente para más de una página',
        () async {
      // Build 25 fake sales → total=25, pageSize=20 → 2 pages.
      final manySales = List.generate(
        25,
        (i) => Sale(
          id: 's$i',
          productName: 'Producto $i',
          sku: 'SKU-$i',
          quantity: 1,
          unitPrice: 10,
          total: 10,
          createdAt: DateTime(2026, 8, 1),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          saleRepositoryProvider
              .overrideWithValue(_FakeSaleRepository(records: manySales)),
        ],
      );
      addTearDown(container.dispose);

      final from = DateTime(2026, 8, 1);
      final to = DateTime(2026, 8, 31);
      final result = await container.read(
        salesPageProvider(
          (from: from, to: to, limit: 20, offset: 0),
        ).future,
      );

      // 25 / 20 = 1.25 → ceil → 2
      final totalPages = (result.total / 20).ceil().clamp(1, 999999);
      expect(totalPages, 2);
    });
  });
}
