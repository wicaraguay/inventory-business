import 'package:flutter/material.dart';
import 'package:inventy_app/features/movements/domain/movement.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';

/// Presentational: the stock movement history. A table on wide screens; compact
/// cards on phones.
class MovementsTable extends StatelessWidget {
  const MovementsTable({required this.movements, super.key});

  final List<Movement> movements;

  static String _fmt(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)} ${two(l.hour)}:${two(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 640;
        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!narrow) ...[
                const _HeaderRow(),
                const Divider(height: 1),
              ],
              Expanded(
                child: ListView.separated(
                  itemCount: movements.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => narrow
                      ? _MobileRow(movement: movements[i], zebra: i.isOdd)
                      : _DataRow(movement: movements[i], zebra: i.isOdd),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _productLabel(Movement m) =>
    m.detail == null ? m.productName : '${m.productName} · ${m.detail}';

class _TypeChip extends StatelessWidget {
  const _TypeChip(this.entry);
  final bool entry;
  @override
  Widget build(BuildContext context) {
    final color = entry ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: entry ? AppColors.successBg : AppColors.dangerBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        entry ? 'Entrada' : 'Salida',
        style: TextStyle(
            color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _MobileRow extends StatelessWidget {
  const _MobileRow({required this.movement, required this.zebra});

  final Movement movement;
  final bool zebra;

  @override
  Widget build(BuildContext context) {
    final entry = movement.isEntry;
    final color = entry ? AppColors.success : AppColors.danger;
    final muted = AppColors.onSurface.withValues(alpha: 0.6);
    return Container(
      color: zebra ? AppColors.canvas : AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _productLabel(movement),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _TypeChip(entry),
                    const SizedBox(width: 8),
                    Text(MovementsTable._fmt(movement.createdAt),
                        style: TextStyle(color: muted, fontSize: 12)),
                  ],
                ),
                if (movement.note != null && movement.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      movement.note!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entry ? '+' : '-'}${movement.quantity}',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.onSurface.withValues(alpha: 0.6),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text('FECHA', style: s)),
          SizedBox(width: 110, child: Text('TIPO', style: s)),
          Expanded(flex: 4, child: Text('PRODUCTO', style: s)),
          SizedBox(width: 90, child: Text('CAMBIO', style: s)),
          Expanded(flex: 3, child: Text('NOTA', style: s)),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.movement, required this.zebra});

  final Movement movement;
  final bool zebra;

  @override
  Widget build(BuildContext context) {
    final entry = movement.isEntry;
    final color = entry ? AppColors.success : AppColors.danger;
    return Container(
      height: 56,
      color: zebra ? AppColors.canvas : AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              MovementsTable._fmt(movement.createdAt),
              style:
                  TextStyle(color: AppColors.onSurface.withValues(alpha: 0.7)),
            ),
          ),
          SizedBox(
            width: 110,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _TypeChip(entry),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(_productLabel(movement),
                overflow: TextOverflow.ellipsis),
          ),
          SizedBox(
            width: 90,
            child: Text(
              '${entry ? '+' : '-'}${movement.quantity}',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              movement.note ?? '—',
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
    );
  }
}
