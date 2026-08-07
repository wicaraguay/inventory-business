import 'package:inventy_backend/src/application/detect_low_stock.dart';
import 'package:inventy_backend/src/domain/entities/low_stock_product.dart';
import 'package:inventy_backend/src/domain/ports/low_stock_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _FakeLowStockRepository extends Mock implements LowStockRepository {}

void main() {
  late _FakeLowStockRepository repository;
  late DetectLowStock useCase;

  setUp(() {
    repository = _FakeLowStockRepository();
    useCase = DetectLowStock(repository);
  });

  test('devuelve los productos en o por debajo del umbral', () async {
    final expected = [
      LowStockProduct(
        productId: 'p1',
        name: 'Botín de cuero',
        detail: 'talle 40',
        sku: 'BOT-40',
        currentStock: 1,
        threshold: 3,
      ),
    ];
    when(() => repository.lowStock()).thenAnswer((_) async => expected);

    final result = await useCase.call();

    expect(result, expected);
    verify(() => repository.lowStock()).called(1);
  });

  test('devuelve lista vacía cuando no hay stock bajo', () async {
    when(() => repository.lowStock()).thenAnswer((_) async => []);

    final result = await useCase.call();

    expect(result, isEmpty);
  });
}
