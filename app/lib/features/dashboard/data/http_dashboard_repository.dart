import 'package:dio/dio.dart';
import 'package:inventy_app/features/dashboard/domain/dashboard_repository.dart';
import 'package:inventy_app/features/dashboard/domain/low_stock_item.dart';

class HttpDashboardRepository implements DashboardRepository {
  HttpDashboardRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<LowStockItem>> lowStock() async {
    final res = await _dio.get<Map<String, dynamic>>('/alerts');
    final items = (res.data!['lowStock'] as List).cast<Map<String, dynamic>>();
    return items.map(LowStockItem.fromJson).toList();
  }

  @override
  Future<void> snoozeAlert(String productId) async {
    await _dio.post<void>('/alerts/snooze', data: {'productId': productId});
  }
}
