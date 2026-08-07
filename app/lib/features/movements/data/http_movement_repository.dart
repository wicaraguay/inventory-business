import 'package:dio/dio.dart';
import 'package:inventy_app/features/movements/domain/movement.dart';
import 'package:inventy_app/features/movements/domain/movement_repository.dart';

class HttpMovementRepository implements MovementRepository {
  HttpMovementRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Movement>> recent() async {
    final res = await _dio.get<Map<String, dynamic>>('/movements');
    final items = (res.data!['movements'] as List).cast<Map<String, dynamic>>();
    return items.map(Movement.fromJson).toList();
  }

  @override
  Future<void> registerEntry({
    required String productId,
    required int quantity,
    String? note,
  }) =>
      _post('entry', productId, quantity, note);

  @override
  Future<void> registerExit({
    required String productId,
    required int quantity,
    String? note,
  }) =>
      _post('exit', productId, quantity, note);

  Future<void> _post(
    String type,
    String productId,
    int quantity,
    String? note,
  ) async {
    try {
      await _dio.post<void>(
        '/movements',
        data: {
          'productId': productId,
          'quantity': quantity,
          'type': type,
          if (note != null) 'note': note,
        },
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map ? data['error']?.toString() : null;
      throw MovementException(
        message ?? 'No se pudo registrar el movimiento',
      );
    }
  }
}
