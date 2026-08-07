import 'package:inventy_backend/src/domain/ports/product_image_repository.dart';

/// Use case: remove a product's image.
class DeleteProductImage {
  DeleteProductImage(this._repository);

  final ProductImageRepository _repository;

  Future<void> call(String productId) {
    return _repository.delete(productId);
  }
}
