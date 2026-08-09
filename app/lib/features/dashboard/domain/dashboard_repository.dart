import 'package:inventy_app/features/dashboard/domain/low_stock_item.dart';

abstract interface class DashboardRepository {
  Future<List<LowStockItem>> lowStock();

  /// Mark a low-stock alert as read (snooze it for a few days).
  Future<void> snoozeAlert(String productId);
}
