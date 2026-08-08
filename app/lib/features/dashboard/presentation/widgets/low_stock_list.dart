import 'package:flutter/material.dart';
import 'package:inventy_app/features/dashboard/domain/low_stock_item.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';
import 'package:inventy_app/shared/ui/atoms/status_pill.dart';

/// Presentational: the low-stock alerts card. [shrinkWrap] sizes it to its
/// content (for the bottom sheet); otherwise it fills its space (dashboard).
class LowStockList extends StatelessWidget {
  const LowStockList({required this.items, this.shrinkWrap = false, super.key});

  final List<LowStockItem> items;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final list = items.isEmpty
        ? const _AllGood()
        : ListView.separated(
            shrinkWrap: shrinkWrap,
            physics: shrinkWrap ? const ClampingScrollPhysics() : null,
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _Row(item: items[i]),
          );
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              'Alertas de stock bajo',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const Divider(height: 1),
          if (shrinkWrap) Flexible(child: list) else Expanded(child: list),
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
    final out = item.currentStock <= 0;
    final status = out ? StockStatus.out : StockStatus.low;
    final color = out ? AppColors.danger : AppColors.warning;
    final muted = AppColors.onSurface.withValues(alpha: 0.6);
    final hasDetail = item.detail != null && item.detail!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            out ? Icons.error_outline : Icons.warning_amber_rounded,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  hasDetail
                      ? '${item.detail}  ·  umbral ${item.threshold}'
                      : 'Umbral ${item.threshold}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusPill(status),
              const SizedBox(height: 4),
              Text(
                out ? 'Agotado' : 'Quedan ${item.currentStock}',
                style: TextStyle(
                  fontSize: 12,
                  color: muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
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
