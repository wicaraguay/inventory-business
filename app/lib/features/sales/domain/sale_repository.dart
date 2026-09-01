import 'package:inventy_app/features/sales/domain/sale.dart';

/// One line in a sale submission.
///
/// For inventory lines set [productId]; leave it null for quick-sale lines.
/// Quick-sale lines require [description] and [total] (the exact amount charged).
/// [sizeLabel] and [createdAt] are optional in both cases.
typedef SaleLine = ({
  String? productId,
  int quantity,
  double unitPrice,
  double? total,
  String? description,
  String? sizeLabel,
  DateTime? createdAt,
});

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

  /// Sales totals for a custom date range (day by day).
  Future<List<SalesBucket>> seriesRange(DateTime from, DateTime to);

  /// All sales (with void info) for a given date range.
  Future<List<Sale>> recordsInRange(DateTime from, DateTime to);

  /// Paginated sales for a date range.
  ///
  /// Returns a record with the page of [records] and [total] (total number of
  /// sales in the range, used to compute pagination).
  Future<({List<Sale> records, int total})> salesPage({
    required DateTime from,
    required DateTime to,
    required int limit,
    required int offset,
  });
}
