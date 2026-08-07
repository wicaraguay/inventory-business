import 'package:inventy_backend/src/domain/entities/product_with_stock.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';
import 'package:inventy_backend/src/domain/ports/product_repository.dart';

/// Use case: resolve a scanned code (the SKU in the QR) to its product + stock.
/// The scanning bridge. Null when the code is unknown.
class FindProductByCode {
  FindProductByCode(this._repository);

  final ProductRepository _repository;

  Future<ProductWithStock?> call(String code) async {
    if (code.trim().isEmpty) {
      throw DomainException('El código es obligatorio');
    }
    return _repository.findByCode(code.trim());
  }
}
