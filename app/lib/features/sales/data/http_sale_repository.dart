import 'package:dio/dio.dart';
import 'package:inventy_app/features/sales/domain/sale.dart';
import 'package:inventy_app/features/sales/domain/sale_repository.dart';

class HttpSaleRepository implements SaleRepository {
  HttpSaleRepository(this._dio);

  final Dio _dio;

  @override
  Future<void> registerSale(List<SaleLine> items) async {
    try {
      await _dio.post<void>(
        '/sales',
        data: {
          'items': items
              .map((i) => {
                    'productId': i.productId,
                    'quantity': i.quantity,
                    'unitPrice': i.unitPrice,
                  })
              .toList(),
        },
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map ? data['error']?.toString() : null;
      throw SaleException(message ?? 'No se pudo registrar la venta');
    }
  }

  @override
  Future<SalesReport> report() async {
    final res = await _dio.get<Map<String, dynamic>>('/sales');
    final data = res.data!;
    final records = (data['sales'] as List)
        .cast<Map<String, dynamic>>()
        .map(Sale.fromJson)
        .toList();
    final summary =
        SalesSummary.fromJson(data['summary'] as Map<String, dynamic>);
    return SalesReport(records: records, summary: summary);
  }

  @override
  Future<List<SalesBucket>> series(String by) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/sales/series',
      queryParameters: {'by': by},
    );
    return (res.data!['series'] as List)
        .cast<Map<String, dynamic>>()
        .map(SalesBucket.fromJson)
        .toList();
  }
}
