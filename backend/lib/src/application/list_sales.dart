import 'package:inventy_backend/src/domain/entities/sale_record.dart';
import 'package:inventy_backend/src/domain/entities/sales_bucket.dart';
import 'package:inventy_backend/src/domain/entities/sales_summary.dart';
import 'package:inventy_backend/src/domain/ports/sales_repository.dart';

/// Use case: read the sales history, summary totals, and time-series.
class ListSales {
  ListSales(this._repository);

  final SalesRepository _repository;

  Future<List<SaleRecord>> records() => _repository.recent();

  Future<SalesSummary> summary() => _repository.summary();

  Future<List<SalesBucket>> series({
    required String by,
    required int buckets,
  }) =>
      _repository.series(by: by, buckets: buckets);
}
