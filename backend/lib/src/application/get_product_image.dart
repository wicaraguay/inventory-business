import 'package:inventy_backend/src/domain/entities/product_image.dart';
import 'package:inventy_backend/src/domain/ports/product_image_repository.dart';

/// Use case: fetch a product's image (null if it has none).
class GetProductImage {
  GetProductImage(this._repository);

  final ProductImageRepository _repository;

  Future<ProductImage?> call(String productId) {
    return _repository.find(productId);
  }
}
