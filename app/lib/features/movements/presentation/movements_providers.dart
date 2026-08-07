import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/movements/data/http_movement_repository.dart';
import 'package:inventy_app/features/movements/domain/movement.dart';
import 'package:inventy_app/features/movements/domain/movement_repository.dart';
import 'package:inventy_app/shared/api/api_client.dart';

final movementRepositoryProvider = Provider<MovementRepository>((ref) {
  return HttpMovementRepository(ref.watch(dioProvider));
});

/// Recent movement history (newest first).
final movementsHistoryProvider = FutureProvider<List<Movement>>((ref) {
  return ref.watch(movementRepositoryProvider).recent();
});
