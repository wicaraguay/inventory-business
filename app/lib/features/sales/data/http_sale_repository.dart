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
          'items': items.map(_lineToJson).toList(),
        },
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map ? data['error']?.toString() : null;
      throw SaleException(message ?? 'No se pudo registrar la venta');
    }
  }

  Map<String, dynamic> _lineToJson(SaleLine line) {
    if (line.productId != null && line.productId!.isNotEmpty) {
      // Inventory line.
      return {
        'productId': line.productId,
        'quantity': line.quantity,
        'unitPrice': line.unitPrice,
      };
    }
    // Quick-sale line (no product).
    final map = <String, dynamic>{
      'quantity': line.quantity,
      'unitPrice': line.unitPrice,
      'total': line.total,
      'description': line.description,
    };
    if (line.sizeLabel != null && line.sizeLabel!.isNotEmpty) {
      map['sizeLabel'] = line.sizeLabel;
    }
    if (line.createdAt != null) {
      // Anchor to LOCAL noon before serializing: showDatePicker yields local
      // midnight, and a naive local->UTC conversion can shift the calendar day
      // in reports (created_at is timestamptz). Noon never crosses the day
      // boundary in any real timezone, so the sale lands on the day she picked.
      final d = line.createdAt!;
      map['createdAt'] = DateTime(d.year, d.month, d.day, 12).toIso8601String();
    }
    return map;
  }

  @override
  Future<void> voidSale(String id) async {
    try {
      await _dio.delete<void>('/sales/$id');
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map ? data['error']?.toString() : null;
      throw SaleException(message ?? 'No se pudo anular la venta');
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

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Future<List<SalesBucket>> seriesRange(DateTime from, DateTime to) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/sales/series',
        queryParameters: {'from': _fmtDate(from), 'to': _fmtDate(to)},
      );
      return (res.data!['series'] as List)
          .cast<Map<String, dynamic>>()
          .map(SalesBucket.fromJson)
          .toList();
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map ? data['error']?.toString() : null;
      throw SaleException(message ?? 'No se pudo obtener las ventas del período');
    }
  }
}
