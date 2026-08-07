import 'package:inventy_backend/src/domain/entities/bulk_product_input.dart';
import 'package:inventy_backend/src/domain/entities/product.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';
import 'package:inventy_backend/src/domain/ports/product_repository.dart';

/// Use case: create many products at once (e.g. all sizes of a model).
class CreateProductsBulk {
  CreateProductsBulk(this._repository);

  final ProductRepository _repository;

  Future<List<Product>> call(List<BulkProductInput> items) async {
    if (items.isEmpty) {
      throw DomainException('No hay productos para crear');
    }
    final seenSkus = <String>{};
    for (final item in items) {
      if (item.name.trim().isEmpty) {
        throw DomainException('El nombre del modelo es obligatorio');
      }
      if (item.sku.trim().isEmpty) {
        throw DomainException('Cada talle necesita un código (SKU)');
      }
      if (!seenSkus.add(item.sku.trim())) {
        throw DomainException('Código repetido: ${item.sku}');
      }
      if (item.lowStockThreshold < 0 ||
          (item.salePrice ?? 0) < 0 ||
          (item.minPrice ?? 0) < 0 ||
          item.initialStock < 0) {
        throw DomainException('Hay valores negativos en la carga');
      }
    }
    return _repository.createBulk(items);
  }
}
