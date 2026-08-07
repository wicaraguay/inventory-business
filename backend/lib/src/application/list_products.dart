import 'package:inventy_backend/src/domain/entities/product_with_stock.dart';
import 'package:inventy_backend/src/domain/ports/product_repository.dart';

/// Use case: list all products with their current stock.
class ListProducts {
  ListProducts(this._repository);

  final ProductRepository _repository;

  Future<List<ProductWithStock>> call() => _repository.listWithStock();
}
