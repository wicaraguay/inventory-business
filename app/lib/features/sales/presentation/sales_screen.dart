import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventy_app/features/auth/presentation/auth_providers.dart';
import 'package:inventy_app/features/dashboard/presentation/dashboard_providers.dart';
import 'package:inventy_app/features/products/presentation/products_providers.dart';
import 'package:inventy_app/features/sales/domain/sale.dart';
import 'package:inventy_app/features/sales/presentation/sales_providers.dart';
import 'package:inventy_app/features/sales/presentation/widgets/sales_table.dart';
import 'package:inventy_app/shared/format.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';
import 'package:inventy_app/shared/ui/app_alert.dart';
import 'package:inventy_app/shared/ui/molecules/metric_card.dart';
import 'package:inventy_app/shared/ui/molecules/metric_card_row.dart';

/// Container: the Ventas section — global totals + date-range sales history.
class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  // Default: last 30 days (from = today - 29, to = today).
  late DateTime _from = DateTime.now().subtract(const Duration(days: 29));
  late DateTime _to = DateTime.now();

  /// One compact control: pick BOTH ends of the range in a single calendar.
  Future<void> _pickRange() async {
    final now = DateTime.now();
    final end = _to.isAfter(now) ? now : _to;
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _from, end: end),
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Elegí el período',
      saveText: 'Listo',
    );
    if (picked == null) return;
    setState(() {
      _from = picked.start;
      _to = picked.end;
    });
  }

  Future<void> _confirmVoid(Sale sale) async {
    final context = this.context;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Anular venta'),
        content: Text(
          '¿Anular la venta de "${sale.productName}" por ${money(sale.total)}? '
          'Se devuelve el stock y queda registrada como anulada (no se borra).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Anular'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(saleRepositoryProvider).voidSale(sale.id);
      ref.invalidate(salesReportProvider);
      ref.invalidate(salesInRangeProvider);
      ref.invalidate(productsProvider); // stock changed
      ref.invalidate(lowStockProvider);
      if (context.mounted) {
        await showAppAlert(context,
            message: 'Venta anulada. Se devolvió el stock.',
            kind: AlertKind.success);
      }
    } on Object catch (e) {
      if (context.mounted) {
        await showAppAlert(context,
            message: 'No se pudo anular: $e'.replaceFirst('Exception: ', ''),
            kind: AlertKind.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(salesReportProvider);
    final salesAsync =
        ref.watch(salesInRangeProvider((from: _from, to: _to)));
    final isOwner = ref.watch(currentUserProvider)?.isOwner ?? false;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ventas',
                        style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Monitoreo de tus ventas',
                      style: TextStyle(
                          color: AppColors.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => context.go('/scan'),
                icon: const Icon(Icons.point_of_sale),
                label: const Text('Nueva venta'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Global metric cards (always from salesReportProvider) ────────
          report.when(
            data: (r) => MetricCardRow([
              MetricCard(
                label: 'Vendido hoy',
                value: money(r.summary.totalToday),
                icon: Icons.point_of_sale,
                accent: AppColors.success,
              ),
              MetricCard(
                label: 'Total general',
                value: money(r.summary.totalAll),
                icon: Icons.summarize_outlined,
              ),
              MetricCard(
                label: 'Ventas',
                value: '${r.summary.count}',
                icon: Icons.receipt_long_outlined,
              ),
            ]),
            loading: () => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Error al cargar métricas: $e'),
          ),

          const SizedBox(height: 16),

          // ── Date-range filter (one compact chip) ─────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: _DateRangeChip(
              from: _from,
              to: _to,
              onTap: _pickRange,
            ),
          ),

          const SizedBox(height: 12),

          // ── Sales table for the selected range ───────────────────────────
          Expanded(
            child: salesAsync.when(
              data: (sales) {
                if (sales.isEmpty) return const _Empty();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Period summary line
                    _PeriodSummary(sales: sales),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SalesTable(
                        sales: sales,
                        canVoid: isOwner,
                        onVoid: _confirmVoid,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error al cargar ventas: $e'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Period summary ─────────────────────────────────────────────────────────

/// Presentational: shows the count and total amount for the current period.
class _PeriodSummary extends StatelessWidget {
  const _PeriodSummary({required this.sales});

  final List<Sale> sales;

  @override
  Widget build(BuildContext context) {
    final active = sales.where((s) => !s.isVoided).toList();
    final total = active.fold<double>(0, (sum, s) => sum + s.total);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${active.length} venta${active.length == 1 ? '' : 's'} · ${money(total)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

// ── Date range chip ────────────────────────────────────────────────────────

/// Presentational: one compact pill showing the selected range (e.g.
/// "30/07 – 28/08"); tapping opens the range picker via [onTap].
class _DateRangeChip extends StatelessWidget {
  const _DateRangeChip({
    required this.from,
    required this.to,
    required this.onTap,
  });

  final DateTime from;
  final DateTime to;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    String d(DateTime x) =>
        '${x.day.toString().padLeft(2, '0')}/${x.month.toString().padLeft(2, '0')}';
    return ActionChip(
      avatar: const Icon(Icons.date_range, size: 18),
      label: Text('${d(from)} – ${d(to)}'),
      onPressed: onTap,
      tooltip: 'Cambiar período',
      shape: const StadiumBorder(),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 48, color: AppColors.inputBorder),
          const SizedBox(height: 12),
          Text('No hay ventas en este período',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Probá con otro rango de fechas.',
            style: TextStyle(
                color: AppColors.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}
