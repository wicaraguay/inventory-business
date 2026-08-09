import 'package:inventy_backend/src/domain/entities/cash_close.dart';

/// PORT: persistence for cash closes (arqueos).
abstract interface class CashRepository {
  Future<CashClose> save({
    required double openingFloat,
    required double salesTotal,
    required double counted,
    required double difference,
    String? closedBy,
  });

  /// Most recent closes (newest first).
  Future<List<CashClose>> recent({int limit = 30});
}
