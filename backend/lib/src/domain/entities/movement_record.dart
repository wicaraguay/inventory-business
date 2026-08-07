import 'package:inventy_backend/src/domain/entities/movement_type.dart';

/// Read model: one stock movement in the history, enriched with product info.
class MovementRecord {
  MovementRecord({
    required this.productName,
    required this.sku,
    required this.type,
    required this.quantity,
    required this.createdAt,
    this.detail,
    this.note,
  });

  final String productName;
  final String? detail;
  final String sku;
  final MovementType type;
  final int quantity;
  final String? note;
  final DateTime createdAt;
}
