import 'package:inventy_backend/src/domain/entities/product.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';
import 'package:inventy_backend/src/domain/ports/product_repository.dart';

/// Use case: update an existing product's fields.
class UpdateProduct {
  UpdateProduct(this._repository);

  final ProductRepository _repository;

  Future<Product> call({
    required String id,
    required String name,
    required String sku,
    int lowStockThreshold = 0,
    String? detail,
    double? salePrice,
    double? minPrice,
    double? supplierPrice,
  }) async {
    if (id.trim().isEmpty) {
      throw DomainException('El producto es obligatorio');
    }
    if (name.trim().isEmpty) {
      throw DomainException('El nombre es obligatorio');
    }
    if (sku.trim().isEmpty) {
      throw DomainException('El código (SKU) es obligatorio');
    }
    if (lowStockThreshold < 0) {
      throw DomainException('El umbral no puede ser negativo');
    }
    if ((salePrice ?? 0) < 0 ||
        (minPrice ?? 0) < 0 ||
        (supplierPrice ?? 0) < 0) {
      throw DomainException('Los precios no pueden ser negativos');
    }
    return _repository.update(
      id: id,
      name: name.trim(),
      sku: sku.trim(),
      lowStockThreshold: lowStockThreshold,
      detail: detail,
      salePrice: salePrice,
      minPrice: minPrice,
      supplierPrice: supplierPrice,
    );
  }
}
