import 'package:inventy_backend/src/domain/entities/model_size.dart';
import 'package:inventy_backend/src/domain/ports/product_repository.dart';

/// Use case: the sizes (with stock) of a model — shown when a product is
/// scanned at the register so the seller sees the other available sizes.
class GetModelSizes {
  GetModelSizes(this._repository);

  final ProductRepository _repository;

  Future<List<ModelSize>> call(String modelId) =>
      _repository.modelSizes(modelId);
}
