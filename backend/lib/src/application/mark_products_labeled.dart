import 'package:inventy_backend/src/domain/ports/product_repository.dart';

/// Use case: mark a set of products as labeled (QR printed + applied) or back
/// to pending. Called after the owner confirms they physically labeled them.
class MarkProductsLabeled {
  MarkProductsLabeled(this._repository);

  final ProductRepository _repository;

  Future<void> call(List<String> ids, {required bool labeled}) =>
      _repository.markLabeled(ids, labeled: labeled);
}
