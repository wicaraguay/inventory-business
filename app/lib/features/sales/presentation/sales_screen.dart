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

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _from : _to;
    final last = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(last) ? last : initial,
      firstDate: DateTime(2020),
      lastDate: last,
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
        if (_from.isAfter(_to)) _to = _from;
      } else {
        _to = picked;
        if (_to.isBefore(_from)) _from = _to;
      }
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

          // ── Date-range filter ────────────────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final pickers = [
                _DatePickerButton(
                  label: 'Desde',
                  date: _from,
                  onTap: () => _pickDate(isFrom: true),
                ),
                const SizedBox(width: 12, height: 12),
                _DatePickerButton(
                  label: 'Hasta',
                  date: _to,
                  onTap: () => _pickDate(isFrom: false),
                ),
              ];
              if (constraints.maxWidth < 400) {
                return Column(children: pickers);
              }
              return Row(
                children: [
                  Expanded(child: pickers[0]),
                  pickers[1],
                  Expanded(child: pickers[2]),
                ],
              );
            },
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

// ── Date picker button ─────────────────────────────────────────────────────

/// Presentational: button that shows a date label and calls [onTap] when pressed.
class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final formatted = '${two(date.day)}/${two(date.month)}/${date.year}';
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Text('$label: $formatted'),
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
