import 'package:inventy_backend/src/domain/entities/movement_record.dart';
import 'package:inventy_backend/src/domain/ports/movement_history_repository.dart';

/// Use case: list the recent stock movement history.
class ListMovements {
  ListMovements(this._repository);

  final MovementHistoryRepository _repository;

  Future<List<MovementRecord>> call({int limit = 100}) =>
      _repository.recent(limit: limit);
}
