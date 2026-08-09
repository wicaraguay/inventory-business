import 'package:inventy_app/features/sales/domain/sale.dart';

/// One line to sell.
typedef SaleLine = ({String productId, int quantity, double unitPrice});

/// Raised when a sale can't be registered (e.g. insufficient stock).
class SaleException implements Exception {
  SaleException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract interface class SaleRepository {
  /// Register a whole sale (one or more lines) atomically.
  Future<void> registerSale(List<SaleLine> items);

  Future<SalesReport> report();

  /// Voids (anula) a sale: reverses it, restores stock, keeps the record.
  Future<void> voidSale(String id);

  /// Sales totals over time for the chart. [by] is 'day' or 'hour'.
  Future<List<SalesBucket>> series(String by);
}
