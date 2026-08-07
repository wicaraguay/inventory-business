import 'package:inventy_backend/src/application/create_products_bulk.dart';
import 'package:inventy_backend/src/domain/entities/bulk_product_input.dart';
import 'package:inventy_backend/src/domain/entities/product.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';
import 'package:inventy_backend/src/domain/ports/product_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _FakeProductRepository extends Mock implements ProductRepository {}

class _FakeBulkInput extends Fake implements BulkProductInput {}

void main() {
  late _FakeProductRepository repository;
  late CreateProductsBulk useCase;

  setUpAll(() {
    registerFallbackValue(<BulkProductInput>[]);
    registerFallbackValue(_FakeBulkInput());
  });

  setUp(() {
    repository = _FakeProductRepository();
    useCase = CreateProductsBulk(repository);
  });

  List<BulkProductInput> sizes(List<String> talles) => [
        for (final t in talles)
          BulkProductInput(
            name: 'Bota de cuero alto',
            sku: 'BOTA-CUERO-$t',
            detail: 'talle $t',
            initialStock: 1,
            salePrice: 250,
            minPrice: 200,
          ),
      ];

  test('crea todos los talles de un modelo de una sola vez', () async {
    final input = sizes(['34', '35', '36', '37', '38', '39', '40']);
    final created = [
      for (final i in input)
        Product(id: i.sku, name: i.name, sku: i.sku, lowStockThreshold: 0),
    ];
    when(() => repository.createBulk(any())).thenAnswer((_) async => created);

    final result = await useCase.call(input);

    expect(result, hasLength(7));
    verify(() => repository.createBulk(input)).called(1);
  });

  test('rechaza lista vacía', () async {
    expect(() => useCase.call([]), throwsA(isA<DomainException>()));
    verifyNever(() => repository.createBulk(any()));
  });

  test('rechaza SKU repetido entre talles', () async {
    final input = [
      BulkProductInput(name: 'Bota', sku: 'DUP-1'),
      BulkProductInput(name: 'Bota', sku: 'DUP-1'),
    ];
    expect(() => useCase.call(input), throwsA(isA<DomainException>()));
    verifyNever(() => repository.createBulk(any()));
  });

  test('rechaza nombre de modelo vacío', () async {
    final input = [BulkProductInput(name: '   ', sku: 'X-1')];
    expect(() => useCase.call(input), throwsA(isA<DomainException>()));
    verifyNever(() => repository.createBulk(any()));
  });

  test('rechaza valores negativos', () async {
    final input = [
      BulkProductInput(name: 'Bota', sku: 'X-1', initialStock: -3),
    ];
    expect(() => useCase.call(input), throwsA(isA<DomainException>()));
    verifyNever(() => repository.createBulk(any()));
  });
}
