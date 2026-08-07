import 'package:dio/dio.dart';
import 'package:inventy_app/features/products/domain/product.dart';
import 'package:inventy_app/features/scanning/domain/scan_repository.dart';

class HttpScanRepository implements ScanRepository {
  HttpScanRepository(this._dio);

  final Dio _dio;

  @override
  Future<Product?> resolve(String code) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/products',
        queryParameters: {'code': code},
      );
      return Product.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
