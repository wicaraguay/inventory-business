import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/sales/data/http_sale_repository.dart';
import 'package:inventy_app/features/sales/domain/sale.dart';
import 'package:inventy_app/features/sales/domain/sale_repository.dart';
import 'package:inventy_app/shared/api/api_client.dart';

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return HttpSaleRepository(ref.watch(dioProvider));
});

final salesReportProvider = FutureProvider<SalesReport>((ref) {
  return ref.watch(saleRepositoryProvider).report();
});

/// Sales time-series for the chart. Family arg is 'day' or 'hour'.
final salesSeriesProvider =
    FutureProvider.family<List<SalesBucket>, String>((ref, by) {
  return ref.watch(saleRepositoryProvider).series(by);
});

/// Sales time-series for a custom date range.
final salesRangeProvider = FutureProvider.family<
    List<SalesBucket>, ({DateTime from, DateTime to})>((ref, r) {
  return ref.watch(saleRepositoryProvider).seriesRange(r.from, r.to);
});

/// All sale records (with void info) for a given date range.
final salesInRangeProvider = FutureProvider.family<
    List<Sale>, ({DateTime from, DateTime to})>((ref, r) {
  return ref.watch(saleRepositoryProvider).recordsInRange(r.from, r.to);
});
