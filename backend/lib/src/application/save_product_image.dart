import 'dart:typed_data';

import 'package:inventy_backend/src/domain/exceptions.dart';
import 'package:inventy_backend/src/domain/ports/product_image_repository.dart';

/// Use case: store (or replace) a product's image.
class SaveProductImage {
  SaveProductImage(this._repository);

  final ProductImageRepository _repository;

  // Guardrail: images are compressed on the client; reject anything absurd.
  static const _maxBytes = 5 * 1024 * 1024;

  Future<void> call(
    String productId,
    Uint8List data,
    String contentType,
  ) async {
    if (productId.trim().isEmpty) {
      throw DomainException('El producto es obligatorio');
    }
    if (data.isEmpty) {
      throw DomainException('La imagen está vacía');
    }
    if (data.length > _maxBytes) {
      throw DomainException('La imagen es demasiado grande');
    }
    await _repository.save(productId.trim(), data, contentType);
  }
}
