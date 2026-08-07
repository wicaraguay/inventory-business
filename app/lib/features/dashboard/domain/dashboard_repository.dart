import 'package:inventy_app/features/dashboard/domain/low_stock_item.dart';

abstract interface class DashboardRepository {
  Future<List<LowStockItem>> lowStock();
}
