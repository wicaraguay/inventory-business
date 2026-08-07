import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/dashboard/data/http_dashboard_repository.dart';
import 'package:inventy_app/features/dashboard/domain/dashboard_repository.dart';
import 'package:inventy_app/features/dashboard/domain/low_stock_item.dart';
import 'package:inventy_app/shared/api/api_client.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return HttpDashboardRepository(ref.watch(dioProvider));
});

final lowStockProvider = FutureProvider<List<LowStockItem>>((ref) {
  return ref.watch(dashboardRepositoryProvider).lowStock();
});
