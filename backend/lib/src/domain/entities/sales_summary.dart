/// Aggregated sales figures for monitoring.
class SalesSummary {
  SalesSummary({
    required this.count,
    required this.totalAll,
    required this.totalToday,
    required this.totalMonth,
    required this.totalYear,
  });

  final int count;
  final double totalAll;
  final double totalToday;
  final double totalMonth;
  final double totalYear;
}
