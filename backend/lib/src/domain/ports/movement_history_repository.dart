import 'package:inventy_backend/src/domain/entities/movement_record.dart';

/// PORT (segregated): read the stock movement history.
abstract interface class MovementHistoryRepository {
  Future<List<MovementRecord>> recent({int limit = 100});
}
