import 'package:inventy_backend/src/application/register_sale.dart';
import 'package:inventy_backend/src/domain/entities/sale_item.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';
import 'package:inventy_backend/src/domain/ports/sales_repository.dart';
import 'package:inventy_backend/src/domain/ports/stock_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _FakeSalesRepository extends Mock implements SalesRepository {}

class _FakeStockRepository extends Mock implements StockRepository {}

class _FakeSaleItem extends Fake implements SaleItem {}

void main() {
  setUpAll(() => registerFallbackValue(<SaleItem>[_FakeSaleItem()]));

  late _FakeSalesRepository sales;
  late _FakeStockRepository stock;
  late RegisterSale useCase;

  setUp(() {
    sales = _FakeSalesRepository();
    stock = _FakeStockRepository();
    useCase = RegisterSale(sales, stock);
  });

  group('venta con producto (inventory sale)', () {
    test('registra la venta cuando hay stock suficiente', () async {
      when(() => stock.currentStock('p1')).thenAnswer((_) async => 10);
      when(() => sales.register(any())).thenAnswer((_) async {});

      await useCase.call([
        SaleItem(productId: 'p1', quantity: 2, unitPrice: 1999.99),
      ]);

      verify(() => sales.register(any())).called(1);
    });

    test('rechaza vender más que el stock disponible (agregando ítems)',
        () async {
      when(() => stock.currentStock('p1')).thenAnswer((_) async => 3);

      await expectLater(
        () => useCase.call([
          SaleItem(productId: 'p1', quantity: 2, unitPrice: 100),
          SaleItem(productId: 'p1', quantity: 2, unitPrice: 100),
        ]),
        throwsA(isA<DomainException>()),
      );
      verifyNever(() => sales.register(any()));
    });

    test('rechaza cantidad <= 0 y precio negativo', () async {
      expect(
        () => useCase
            .call([SaleItem(productId: 'p1', quantity: 0, unitPrice: 1)]),
        throwsA(isA<DomainException>()),
      );
      expect(
        () => useCase
            .call([SaleItem(productId: 'p1', quantity: 1, unitPrice: -5)]),
        throwsA(isA<DomainException>()),
      );
    });

    test('consulta stock solo para items con productId', () async {
      when(() => stock.currentStock('p1')).thenAnswer((_) async => 10);
      when(() => sales.register(any())).thenAnswer((_) async {});

      await useCase.call([
        SaleItem(
          productId: 'p1',
          quantity: 1,
          unitPrice: 100,
        ),
        SaleItem(
          // quick sale alongside inventory sale
          quantity: 2,
          unitPrice: 50,
          description: 'Zapatillas genéricas',
        ),
      ]);

      // stock was checked for p1 only
      verify(() => stock.currentStock('p1')).called(1);
      verifyNever(() => stock.currentStock(any(
            that: isNot('p1'),
          )));
      verify(() => sales.register(any())).called(1);
    });
  });

  group('venta rápida (quick sale — sin productId)', () {
    test('NO llama a stock.currentStock y sí llama a sales.register', () async {
      when(() => sales.register(any())).thenAnswer((_) async {});

      await useCase.call([
        SaleItem(
          quantity: 3,
          unitPrice: 1500,
          description: 'Sandalias negras talle 38',
        ),
      ]);

      verifyNever(() => stock.currentStock(any()));
      verify(() => sales.register(any())).called(1);
    });

    test('acepta productId nulo', () async {
      when(() => sales.register(any())).thenAnswer((_) async {});

      await useCase.call([
        SaleItem(
          productId: null,
          quantity: 1,
          unitPrice: 2000,
          description: 'Bota de cuero',
        ),
      ]);

      verifyNever(() => stock.currentStock(any()));
      verify(() => sales.register(any())).called(1);
    });

    test('acepta productId vacío como venta rápida', () async {
      when(() => sales.register(any())).thenAnswer((_) async {});

      await useCase.call([
        SaleItem(
          productId: '',
          quantity: 1,
          unitPrice: 800,
          description: 'Ojota azul',
        ),
      ]);

      verifyNever(() => stock.currentStock(any()));
      verify(() => sales.register(any())).called(1);
    });

    test('lanza DomainException cuando description es null', () async {
      expect(
        () => useCase.call([
          SaleItem(quantity: 1, unitPrice: 500),
        ]),
        throwsA(
          isA<DomainException>().having(
            (e) => e.message,
            'message',
            contains('descripción'),
          ),
        ),
      );
      verifyNever(() => sales.register(any()));
    });

    test('lanza DomainException cuando description está vacía', () async {
      expect(
        () => useCase.call([
          SaleItem(quantity: 1, unitPrice: 500, description: '   '),
        ]),
        throwsA(
          isA<DomainException>().having(
            (e) => e.message,
            'message',
            contains('descripción'),
          ),
        ),
      );
      verifyNever(() => sales.register(any()));
    });

    test('admite sizeLabel opcional', () async {
      when(() => sales.register(any())).thenAnswer((_) async {});

      await useCase.call([
        SaleItem(
          quantity: 1,
          unitPrice: 2500,
          description: 'Zapatilla deportiva',
          sizeLabel: '42',
        ),
      ]);

      verify(() => sales.register(any())).called(1);
    });

    test('admite createdAt opcional para back-dating', () async {
      when(() => sales.register(any())).thenAnswer((_) async {});

      final pastDate = DateTime(2026, 8, 1);
      await useCase.call([
        SaleItem(
          quantity: 2,
          unitPrice: 1800,
          description: 'Mocasín marrón',
          createdAt: pastDate,
        ),
      ]);

      final captured = verify(() => sales.register(captureAny())).captured;
      final items = captured.first as List<SaleItem>;
      expect(items.first.createdAt, pastDate);
    });
  });

  test('rechaza venta vacía', () async {
    expect(() => useCase.call([]), throwsA(isA<DomainException>()));
  });
}
