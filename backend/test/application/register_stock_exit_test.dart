import 'package:inventy_backend/src/application/register_stock_exit.dart';
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
  late RegisterStockExit useCase;

  setUp(() {
    repository = _FakeStockRepository();
    useCase = RegisterStockExit(repository);
  });

  test('registra una salida cuando hay stock suficiente', () async {
    when(() => repository.currentStock('product-1')).thenAnswer((_) async => 10);
    when(() => repository.save(any())).thenAnswer((_) async {});

    await useCase.call('product-1', 4);

    final saved = verify(() => repository.save(captureAny())).captured.single
        as StockMovement;
    expect(saved.type, MovementType.exit);
    expect(saved.quantity, 4);
  });

  test('rechaza sacar más de lo disponible (stock insuficiente)', () async {
    when(() => repository.currentStock('product-1')).thenAnswer((_) async => 3);

    expect(
      () => useCase.call('product-1', 5),
      throwsA(isA<DomainException>()),
    );
    verifyNever(() => repository.save(any()));
  });

  test('rechaza cantidad menor o igual a cero sin consultar stock', () async {
    expect(() => useCase.call('product-1', 0), throwsA(isA<DomainException>()));
    verifyNever(() => repository.currentStock(any()));
    verifyNever(() => repository.save(any()));
  });

  test('rechaza producto vacío', () async {
    expect(() => useCase.call('  ', 5), throwsA(isA<DomainException>()));
    verifyNever(() => repository.save(any()));
  });
}
