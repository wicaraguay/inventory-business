import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:inventy_app/features/products/domain/bulk_product_input.dart';
import 'package:inventy_app/features/products/domain/product.dart';
import 'package:inventy_app/features/products/domain/product_repository.dart';

class HttpProductRepository implements ProductRepository {
  HttpProductRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Product>> list() async {
    final res = await _dio.get<Map<String, dynamic>>('/products');
    final items = (res.data!['products'] as List).cast<Map<String, dynamic>>();
    return items.map(Product.fromJson).toList();
  }

  @override
  Future<Product> create({
    required String name,
    required String sku,
    required int lowStockThreshold,
    String? detail,
    double? salePrice,
    double? minPrice,
    double? supplierPrice,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/products',
      data: {
        'name': name,
        'sku': sku,
        'lowStockThreshold': lowStockThreshold,
        if (detail != null) 'detail': detail,
        if (salePrice != null) 'salePrice': salePrice,
        if (minPrice != null) 'minPrice': minPrice,
        if (supplierPrice != null) 'supplierPrice': supplierPrice,
      },
    );
    return Product.fromJson(res.data!);
  }

  @override
  Future<List<Product>> createBulk(List<BulkProductInput> items) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/products',
        data: {'items': items.map((i) => i.toJson()).toList()},
      );
      final created =
          (res.data!['products'] as List).cast<Map<String, dynamic>>();
      return created.map(Product.fromJson).toList();
    } on DioException catch (e) {
      throw Exception(_backendError(e) ?? 'No se pudo registrar la carga.');
    }
  }

  @override
  Future<List<Product>> addModelSizes(
    String modelId,
    List<BulkProductInput> items,
  ) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/products/model/$modelId/sizes',
        data: {'items': items.map((i) => i.toJson()).toList()},
      );
      final created =
          (res.data!['products'] as List).cast<Map<String, dynamic>>();
      return created.map(Product.fromJson).toList();
    } on DioException catch (e) {
      throw Exception(_backendError(e) ?? 'No se pudieron agregar las tallas.');
    }
  }

  /// The backend's friendly `{"error": "..."}` message, if any.
  static String? _backendError(DioException e) {
    final data = e.response?.data;
    return data is Map ? data['error']?.toString() : null;
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    required String sku,
    required int lowStockThreshold,
    String? detail,
    double? salePrice,
    double? minPrice,
    double? supplierPrice,
  }) async {
    await _dio.put<void>(
      '/products/$id',
      data: {
        'name': name,
        'sku': sku,
        'lowStockThreshold': lowStockThreshold,
        'detail': detail,
        'salePrice': salePrice,
        'minPrice': minPrice,
        'supplierPrice': supplierPrice,
      },
    );
  }

  @override
  Future<void> delete(String id) async {
    await _dio.delete<void>('/products/$id');
  }

  @override
  Future<void> markLabeled(List<String> ids, {required bool labeled}) async {
    await _dio.post<void>(
      '/products/mark-labeled',
      data: {'ids': ids, 'labeled': labeled},
    );
  }

  @override
  Future<void> uploadImage(String id, Uint8List bytes) async {
    await _dio.put<void>(
      '/products/$id/image',
      data: Stream.fromIterable([bytes]),
      options: Options(
        contentType: 'image/jpeg',
        headers: {Headers.contentLengthHeader: bytes.length},
      ),
    );
  }

  @override
  Future<void> deleteImage(String id) async {
    await _dio.delete<void>('/products/$id/image');
  }
}
