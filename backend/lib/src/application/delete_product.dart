import 'package:inventy_backend/src/domain/exceptions.dart';
import 'package:inventy_backend/src/domain/ports/product_repository.dart';

/// Use case: delete a product (and its movements/sales via cascade).
class DeleteProduct {
  DeleteProduct(this._repository);

  final ProductRepository _repository;

  Future<void> call(String id) async {
    if (id.trim().isEmpty) {
      throw DomainException('El producto es obligatorio');
    }
    await _repository.delete(id);
  }
}
