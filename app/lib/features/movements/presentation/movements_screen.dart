import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/movements/presentation/movements_providers.dart';
import 'package:inventy_app/features/movements/presentation/widgets/movements_table.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';

/// Container: the Movimientos section — stock movement history.
class MovementsScreen extends ConsumerWidget {
  const MovementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(movementsHistoryProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Movimientos', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text(
            'Historial de entradas y salidas de stock',
            style: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: history.when(
              data: (items) => items.isEmpty
                  ? const _Empty()
                  : MovementsTable(movements: items),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_vert, size: 48, color: AppColors.inputBorder),
          const SizedBox(height: 12),
          Text('Sin movimientos',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Registrá entradas o salidas desde Inventario o Escanear.',
            style: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}
