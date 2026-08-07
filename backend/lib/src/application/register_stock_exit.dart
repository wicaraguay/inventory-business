import 'package:inventy_backend/src/domain/entities/movement_type.dart';
import 'package:inventy_backend/src/domain/entities/stock_movement.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';
import 'package:inventy_backend/src/domain/ports/stock_repository.dart';

/// Use case: register an outbound stock exit for a product.
/// Business rule: you cannot take out more than what is currently in stock.
class RegisterStockExit {
  RegisterStockExit(this._repository);

  final StockRepository _repository;

  Future<void> call(String productId, int quantity, {String? note}) async {
    if (productId.trim().isEmpty) {
      throw DomainException('El producto es obligatorio');
    }
    if (quantity <= 0) {
      throw DomainException('La cantidad debe ser positiva');
    }

    final available = await _repository.currentStock(productId);
    if (quantity > available) {
      throw DomainException(
        'Stock insuficiente: hay $available, se intentó sacar $quantity',
      );
    }

    await _repository.save(
      StockMovement(
        productId: productId,
        quantity: quantity,
        type: MovementType.exit,
        note: note,
      ),
    );
  }
}
