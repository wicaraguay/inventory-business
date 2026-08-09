import 'package:dio/dio.dart';
import 'package:inventy_app/features/sales/domain/cash_close.dart';

class HttpCashRepository {
  HttpCashRepository(this._dio);

  final Dio _dio;

  Future<CashClose> save({
    required double openingFloat,
    required double salesTotal,
    required double counted,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/cash',
      data: {
        'openingFloat': openingFloat,
        'salesTotal': salesTotal,
        'counted': counted,
      },
    );
    return CashClose.fromJson(res.data!);
  }

  Future<List<CashClose>> recent() async {
    final res = await _dio.get<Map<String, dynamic>>('/cash');
    return (res.data!['closes'] as List)
        .cast<Map<String, dynamic>>()
        .map(CashClose.fromJson)
        .toList();
  }
}
