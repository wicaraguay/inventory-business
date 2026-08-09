import 'package:inventy_backend/src/domain/entities/cash_close.dart';
import 'package:inventy_backend/src/domain/ports/cash_repository.dart';

/// Use case: save an end-of-day cash close (arqueo).
class SaveCashClose {
  SaveCashClose(this._repository);

  final CashRepository _repository;

  Future<CashClose> call({
    required double openingFloat,
    required double salesTotal,
    required double counted,
    String? closedBy,
  }) {
    final difference = counted - (openingFloat + salesTotal);
    return _repository.save(
      openingFloat: openingFloat,
      salesTotal: salesTotal,
      counted: counted,
      difference: difference,
      closedBy: closedBy,
    );
  }
}

/// Use case: list the recent cash closes.
class ListCashCloses {
  ListCashCloses(this._repository);

  final CashRepository _repository;

  Future<List<CashClose>> call() => _repository.recent();
}
