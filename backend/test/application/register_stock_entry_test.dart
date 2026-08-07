import 'package:inventy_backend/src/application/register_stock_entry.dart';
import 'package:inventy_backend/src/domain/entities/movement_type.dart';
import 'package:inventy_backend/src/domain/entities/stock_movement.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';
import 'package:inventy_backend/src/domain/ports/stock_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _FakeStockRepository extends Mock implements StockRepository {}

class _FakeStockMovement extends Fake implements StockMovement {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeStockMovement()));

  late _FakeStockRepository repository;
  late RegisterStockEntry useCase;

  setUp(() {
    repository = _FakeStockRepository();
    useCase = RegisterStockEntry(repository);
  });

  test('registra una entrada de tipo entry con la cantidad dada', () async {
    when(() => repository.save(any())).thenAnswer((_) async {});

    await useCase.call('product-1', 5);

    final saved = verify(() => repository.save(captureAny())).captured.single
        as StockMovement;
    expect(saved.productId, 'product-1');
    expect(saved.quantity, 5);
    expect(saved.type, MovementType.entry);
  });

  test('rechaza cantidad menor o igual a cero', () async {
    expect(() => useCase.call('product-1', 0), throwsA(isA<DomainException>()));
    verifyNever(() => repository.save(any()));
  });

  test('rechaza producto vacío', () async {
    expect(() => useCase.call('  ', 5), throwsA(isA<DomainException>()));
    verifyNever(() => repository.save(any()));
  });
}
