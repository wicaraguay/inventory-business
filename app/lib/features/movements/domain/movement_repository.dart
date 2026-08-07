import 'package:inventy_app/features/movements/domain/movement.dart';

/// Raised when a movement can't be registered (e.g. insufficient stock).
/// Carries the human message from the backend.
class MovementException implements Exception {
  MovementException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract interface class MovementRepository {
  /// Recent movement history (newest first).
  Future<List<Movement>> recent();

  Future<void> registerEntry({
    required String productId,
    required int quantity,
    String? note,
  });

  Future<void> registerExit({
    required String productId,
    required int quantity,
    String? note,
  });
}
