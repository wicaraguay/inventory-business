import 'package:inventy_backend/src/domain/entities/movement_type.dart';
import 'package:inventy_backend/src/domain/entities/stock_movement.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';
import 'package:inventy_backend/src/domain/ports/stock_repository.dart';

/// Use case: register an inbound stock entry for a product.
class RegisterStockEntry {
  RegisterStockEntry(this._repository);

  final StockRepository _repository;

  Future<void> call(String productId, int quantity, {String? note}) async {
    if (productId.trim().isEmpty) {
      throw DomainException('El producto es obligatorio');
    }
    if (quantity <= 0) {
      throw DomainException('La cantidad debe ser positiva');
    }

    await _repository.save(
      StockMovement(
        productId: productId,
        quantity: quantity,
        type: MovementType.entry,
        note: note,
      ),
    );
  }
}
