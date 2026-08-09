import 'package:inventy_backend/src/domain/entities/bulk_product_input.dart';
import 'package:inventy_backend/src/domain/entities/product.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';
import 'package:inventy_backend/src/domain/ports/product_repository.dart';

/// Use case: add more sizes to an existing model, reusing its model_id and
/// image. Used when a series was created incomplete (e.g. missing 35/36).
class AddModelSizes {
  AddModelSizes(this._repository);

  final ProductRepository _repository;

  Future<List<Product>> call(String modelId, List<BulkProductInput> items) async {
    if (modelId.trim().isEmpty) {
      throw DomainException('Modelo inválido');
    }
    if (items.isEmpty) {
      throw DomainException('No hay tallas para agregar');
    }
    final seenSkus = <String>{};
    for (final item in items) {
      if (item.sku.trim().isEmpty) {
        throw DomainException('Cada talle necesita un código (SKU)');
      }
      if (!seenSkus.add(item.sku.trim())) {
        throw DomainException('Talla repetida en la carga: ${item.sku}');
      }
      if (item.lowStockThreshold < 0 ||
          (item.salePrice ?? 0) < 0 ||
          (item.minPrice ?? 0) < 0 ||
          item.initialStock < 0) {
        throw DomainException('Hay valores negativos en la carga');
      }
    }
    return _repository.addSizesToModel(modelId.trim(), items);
  }
}
