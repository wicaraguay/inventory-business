import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/sales/data/http_cash_repository.dart';
import 'package:inventy_app/features/sales/domain/cash_close.dart';
import 'package:inventy_app/shared/api/api_client.dart';

final cashRepositoryProvider = Provider<HttpCashRepository>(
  (ref) => HttpCashRepository(ref.watch(dioProvider)),
);

/// Recent saved cash closes (history).
final cashClosesProvider = FutureProvider<List<CashClose>>(
  (ref) => ref.watch(cashRepositoryProvider).recent(),
);
