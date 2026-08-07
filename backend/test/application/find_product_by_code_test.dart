import 'package:inventy_backend/src/application/find_product_by_code.dart';
import 'package:inventy_backend/src/domain/entities/product.dart';
import 'package:inventy_backend/src/domain/entities/product_with_stock.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';
import 'package:inventy_backend/src/domain/ports/product_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _FakeProductRepository extends Mock implements ProductRepository {}

void main() {
  late _FakeProductRepository repository;
  late FindProductByCode useCase;

  setUp(() {
    repository = _FakeProductRepository();
    useCase = FindProductByCode(repository);
  });

  test('devuelve el producto con stock cuando el código existe', () async {
    final expected = ProductWithStock(
      product: Product(
        id: 'p1',
        name: 'Botín de cuero',
        sku: 'BOT-40',
        lowStockThreshold: 3,
      ),
      currentStock: 12,
    );
    when(() => repository.findByCode('BOT-40'))
        .thenAnswer((_) async => expected);

    final result = await useCase.call('  BOT-40  ');

    expect(result?.product.id, 'p1');
    expect(result?.currentStock, 12);
    verify(() => repository.findByCode('BOT-40')).called(1);
  });

  test('devuelve null cuando el código no existe', () async {
    when(() => repository.findByCode(any())).thenAnswer((_) async => null);

    final result = await useCase.call('0000');

    expect(result, isNull);
  });

  test('rechaza código vacío', () async {
    expect(() => useCase.call('  '), throwsA(isA<DomainException>()));
    verifyNever(() => repository.findByCode(any()));
  });
}
