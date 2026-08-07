import 'package:inventy_backend/src/application/create_product.dart';
import 'package:inventy_backend/src/domain/entities/product.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';
import 'package:inventy_backend/src/domain/ports/product_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _FakeProductRepository extends Mock implements ProductRepository {}

void main() {
  late _FakeProductRepository repository;
  late CreateProduct useCase;

  setUp(() {
    repository = _FakeProductRepository();
    useCase = CreateProduct(repository);
  });

  test('crea un producto válido (recortando espacios)', () async {
    final created = Product(
      id: 'p1',
      name: 'Botín de cuero',
      sku: 'BOT-40',
      lowStockThreshold: 3,
    );
    when(
      () => repository.create(
        name: any(named: 'name'),
        sku: any(named: 'sku'),
        lowStockThreshold: any(named: 'lowStockThreshold'),
        detail: any(named: 'detail'),
      ),
    ).thenAnswer((_) async => created);

    final result = await useCase.call(
      name: '  Botín de cuero  ',
      sku: '  BOT-40  ',
      lowStockThreshold: 3,
      detail: 'talle 40 · negro',
    );

    expect(result.id, 'p1');
    verify(
      () => repository.create(
        name: 'Botín de cuero',
        sku: 'BOT-40',
        lowStockThreshold: 3,
        detail: 'talle 40 · negro',
      ),
    ).called(1);
  });

  test('rechaza nombre vacío', () async {
    expect(
      () => useCase.call(name: '   ', sku: 'BOT-40'),
      throwsA(isA<DomainException>()),
    );
  });

  test('rechaza SKU vacío', () async {
    expect(
      () => useCase.call(name: 'Botín', sku: '  '),
      throwsA(isA<DomainException>()),
    );
  });
}
