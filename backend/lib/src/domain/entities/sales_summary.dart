/// Aggregated sales figures for monitoring. For each time range we track both
/// revenue (what was charged) and estimated profit (revenue - cost, where cost
/// is the product's current supplier price; unknown costs count as 0).
class SalesSummary {
  SalesSummary({
    required this.count,
    required this.totalAll,
    required this.totalToday,
    required this.totalWeek,
    required this.totalMonth,
    required this.totalQuarter,
    required this.totalYear,
    required this.profitToday,
    required this.profitWeek,
    required this.profitMonth,
    required this.profitQuarter,
    required this.profitYear,
  });

  final int count;
  final double totalAll;

  // Revenue per range.
  final double totalToday;
  final double totalWeek; // last 7 days
  final double totalMonth;
  final double totalQuarter;
  final double totalYear;

  // Estimated profit per range (revenue - cost).
  final double profitToday;
  final double profitWeek;
  final double profitMonth;
  final double profitQuarter;
  final double profitYear;
}
