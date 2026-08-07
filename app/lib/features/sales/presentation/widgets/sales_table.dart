import 'package:flutter/material.dart';
import 'package:inventy_app/features/sales/domain/sale.dart';
import 'package:inventy_app/shared/format.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';

/// Presentational: the sales history. A table on wide screens; compact cards on
/// phones (where the fixed columns wouldn't fit).
class SalesTable extends StatelessWidget {
  const SalesTable({required this.sales, super.key});

  final List<Sale> sales;

  static String _fmt(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)} ${two(l.hour)}:${two(l.minute)}';
  }

  bool _isNew(Sale sale, DateTime? newest) =>
      newest != null &&
      sale.createdAt.isAfter(newest.subtract(const Duration(seconds: 5)));

  @override
  Widget build(BuildContext context) {
    // Sales come newest-first; highlight the last transaction (within 5s).
    final newest = sales.isEmpty ? null : sales.first.createdAt;
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
                  itemCount: sales.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final sale = sales[i];
                    final highlighted = _isNew(sale, newest);
                    return narrow
                        ? _MobileRow(
                            sale: sale, zebra: i.isOdd, highlighted: highlighted)
                        : _DataRow(
                            sale: sale, zebra: i.isOdd, highlighted: highlighted);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Color _rowColor(bool highlighted, bool zebra) => highlighted
    ? AppColors.primary.withValues(alpha: 0.10)
    : (zebra ? AppColors.canvas : AppColors.surface);

String _productLabel(Sale sale) => sale.detail == null
    ? sale.productName
    : '${sale.productName} · ${sale.detail}';

class _NewBadge extends StatelessWidget {
  const _NewBadge();
  @override
  Widget build(BuildContext context) => Text(
        'Nueva',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      );
}

class _MobileRow extends StatelessWidget {
  const _MobileRow({
    required this.sale,
    required this.zebra,
    required this.highlighted,
  });

  final Sale sale;
  final bool zebra;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.onSurface.withValues(alpha: 0.6);
    return Container(
      color: _rowColor(highlighted, zebra),
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
                  _productLabel(sale),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(SalesTable._fmt(sale.createdAt),
                        style: TextStyle(color: muted, fontSize: 12)),
                    if (highlighted) ...[
                      const SizedBox(width: 8),
                      const _NewBadge(),
                    ],
                  ],
                ),
                Text(
                  '${sale.quantity} × ${money(sale.unitPrice)}',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            money(sale.total),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
          Expanded(flex: 4, child: Text('PRODUCTO', style: s)),
          SizedBox(width: 70, child: Text('CANT', style: s)),
          SizedBox(width: 110, child: Text('P. UNIT', style: s)),
          SizedBox(width: 110, child: Text('TOTAL', style: s)),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.sale,
    required this.zebra,
    required this.highlighted,
  });

  final Sale sale;
  final bool zebra;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: _rowColor(highlighted, zebra),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(SalesTable._fmt(sale.createdAt),
                    style: TextStyle(
                        color: AppColors.onSurface.withValues(alpha: 0.7))),
                if (highlighted) const _NewBadge(),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(_productLabel(sale), overflow: TextOverflow.ellipsis),
          ),
          SizedBox(width: 70, child: Text('${sale.quantity}')),
          SizedBox(width: 110, child: Text(money(sale.unitPrice))),
          SizedBox(
            width: 110,
            child: Text(
              money(sale.total),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
