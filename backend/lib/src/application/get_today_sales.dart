import 'package:inventy_backend/src/domain/ports/sales_repository.dart';

/// Use case: today's sales total + count — the figure the cash close needs.
class GetTodaySales {
  GetTodaySales(this._sales);

  final SalesRepository _sales;

  Future<({double total, int count})> call() => _sales.todayTotals();
}
