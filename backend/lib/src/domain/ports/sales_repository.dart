import 'package:inventy_backend/src/domain/entities/sale_item.dart';
import 'package:inventy_backend/src/domain/entities/sale_record.dart';
import 'package:inventy_backend/src/domain/entities/sales_bucket.dart';
import 'package:inventy_backend/src/domain/entities/sales_summary.dart';

/// PORT: persistence contract for sales.
abstract interface class SalesRepository {
  /// Register all lines of a sale atomically (one transaction).
  Future<void> register(List<SaleItem> items);

  Future<List<SaleRecord>> recent({int limit = 100});

  /// Voids a sale (soft): marks it, restores stock, keeps the record.
  Future<void> voidSale(String id, String? by);

  Future<SalesSummary> summary();

  /// Time-series of sales totals. [by] is 'day' or 'hour'; [buckets] is how
  /// many periods back to include (zero-filled).
  Future<List<SalesBucket>> series({required String by, required int buckets});
}
