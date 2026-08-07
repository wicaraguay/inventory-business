import 'package:flutter/material.dart';
import 'package:inventy_app/features/dashboard/domain/low_stock_item.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';
import 'package:inventy_app/shared/ui/atoms/status_pill.dart';

/// Presentational: the low-stock alerts card.
class LowStockList extends StatelessWidget {
  const LowStockList({required this.items, super.key});

  final List<LowStockItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              'Alertas de stock bajo',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: items.isEmpty
                ? const _AllGood()
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _Row(item: items[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item});

  final LowStockItem item;

  @override
  Widget build(BuildContext context) {
    final status =
        item.currentStock <= 0 ? StockStatus.out : StockStatus.low;
    final subtitle = [
      if (item.detail != null && item.detail!.isNotEmpty) item.detail!,
      '${item.sku}  ·  ${item.currentStock} de ${item.threshold}',
    ].join('  ·  ');
    return ListTile(
      leading: const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
      title: Text(item.name),
      subtitle: Text(subtitle),
      trailing: StatusPill(status),
    );
  }
}

class _AllGood extends StatelessWidget {
  const _AllGood();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 48, color: AppColors.success),
          const SizedBox(height: 12),
          Text('Todo en orden',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'No hay variantes por debajo de su umbral.',
            style: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}
