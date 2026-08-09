import 'package:inventy_backend/src/domain/ports/sales_repository.dart';

/// Use case: void (anular) a sale — reverses it without deleting the record.
class VoidSale {
  VoidSale(this._sales);

  final SalesRepository _sales;

  Future<void> call(String id, String? by) => _sales.voidSale(id, by);
}
