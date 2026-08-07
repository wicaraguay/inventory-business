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

    expect(
      () => useCase.call([
        SaleItem(productId: 'p1', quantity: 2, unitPrice: 100),
        SaleItem(productId: 'p1', quantity: 2, unitPrice: 100),
      ]),
      throwsA(isA<DomainException>()),
    );
    verifyNever(() => sales.register(any()));
  });

  test('rechaza venta vacía, cantidad <= 0 y precio negativo', () async {
    expect(() => useCase.call([]), throwsA(isA<DomainException>()));
    expect(
      () =>
          useCase.call([SaleItem(productId: 'p1', quantity: 0, unitPrice: 1)]),
      throwsA(isA<DomainException>()),
    );
    expect(
      () =>
          useCase.call([SaleItem(productId: 'p1', quantity: 1, unitPrice: -5)]),
      throwsA(isA<DomainException>()),
    );
  });
}
