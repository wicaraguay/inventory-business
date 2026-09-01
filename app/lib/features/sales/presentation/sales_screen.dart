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

const _pageSize = 20;

const _monthNames = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

/// Container: the Ventas section — global totals + month navigator + paginated
/// sales history.
class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  // Local UI state: selected month (first day) and current page index.
  late DateTime _month = _firstDayOfCurrentMonth();
  int _page = 0;

  static DateTime _firstDayOfCurrentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  /// First day of the selected month.
  DateTime get _from => _month;

  /// Last day of the selected month (day 0 of the following month).
  DateTime get _to => DateTime(_month.year, _month.month + 1, 0);

  void _prevMonth() {
    setState(() {
      _month = DateTime(_month.year, _month.month - 1, 1);
      _page = 0;
    });
  }

  void _nextMonth() {
    setState(() {
      _month = DateTime(_month.year, _month.month + 1, 1);
      _page = 0;
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
      ref.invalidate(salesPageProvider);
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
    final salesAsync = ref.watch(salesPageProvider((
      from: _from,
      to: _to,
      limit: _pageSize,
      offset: _page * _pageSize,
    )));
    final isOwner = ref.watch(currentUserProvider)?.isOwner ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ventas',
                        style: Theme.of(context).textTheme.headlineMedium,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      'Monitoreo de tus ventas',
                      style: TextStyle(
                          color: AppColors.onSurface.withValues(alpha: 0.6),
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => context.go('/scan'),
                icon: const Icon(Icons.point_of_sale, size: 18),
                label: const Text('Nueva venta'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

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
                label: 'Vendido este mes',
                value: money(r.summary.totalMonth),
                icon: Icons.calendar_month_outlined,
                accent: AppColors.primary,
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

          const SizedBox(height: 12),

          // ── Month navigator ──────────────────────────────────────────────
          _MonthNavigator(
            month: _month,
            isCurrentMonth: _isCurrentMonth,
            onPrev: _prevMonth,
            onNext: _isCurrentMonth ? null : _nextMonth,
          ),

          const SizedBox(height: 10),

          // ── Sales table for the selected month ───────────────────────────
          Expanded(
            child: salesAsync.when(
              data: (page) {
                final sales = page.records;
                final total = page.total;
                final totalPages = (total / _pageSize).ceil().clamp(1, 999999);

                if (sales.isEmpty && _page == 0) {
                  return const _Empty();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Period summary line
                    _PeriodSummary(total: total),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SalesTable(
                        sales: sales,
                        canVoid: isOwner,
                        onVoid: _confirmVoid,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Pagination controls
                    _PaginationBar(
                      page: _page,
                      totalPages: totalPages,
                      onPrev: _page == 0
                          ? null
                          : () => setState(() => _page--),
                      onNext: _page + 1 >= totalPages
                          ? null
                          : () => setState(() => _page++),
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

// ── Month navigator ────────────────────────────────────────────────────────

/// Presentational: ‹ Agosto 2026 › with the › disabled when in current month.
///
/// Uses a fixed-width [SizedBox] for each icon button so the label stays
/// perfectly centred in any screen width without risk of overflow.
class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.month,
    required this.isCurrentMonth,
    required this.onPrev,
    this.onNext,
  });

  final DateTime month;
  final bool isCurrentMonth;
  final VoidCallback onPrev;

  /// Null to disable the forward arrow.
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final label = '${_monthNames[month.month - 1]} ${month.year}';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.inputBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 44,
            child: IconButton(
              key: const Key('month-prev'),
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Mes anterior',
              onPressed: onPrev,
            ),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          SizedBox(
            width: 44,
            child: IconButton(
              key: const Key('month-next'),
              icon: Icon(
                Icons.chevron_right,
                color: isCurrentMonth
                    ? AppColors.onSurface.withValues(alpha: 0.3)
                    : null,
              ),
              tooltip: isCurrentMonth ? null : 'Mes siguiente',
              onPressed: onNext,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Period summary ─────────────────────────────────────────────────────────

/// Presentational: shows the total count of sales in the month from the
/// backend (includes all pages).
class _PeriodSummary extends StatelessWidget {
  const _PeriodSummary({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$total venta${total == 1 ? '' : 's'} en el mes',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface.withValues(alpha: 0.75),
                ),
          ),
        ],
      ),
    );
  }
}

// ── Pagination bar ─────────────────────────────────────────────────────────

/// Presentational: Anterior / Página X de Y / Siguiente.
///
/// Uses [Expanded] for the page-indicator so the two buttons stay pinned to
/// the edges and never overflow on narrow screens.
class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          key: const Key('page-prev'),
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left, size: 18),
          label: const Text('Anterior'),
        ),
        Expanded(
          child: Text(
            'Página ${page + 1} de $totalPages',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        TextButton.icon(
          key: const Key('page-next'),
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right, size: 18),
          label: const Text('Siguiente'),
          iconAlignment: IconAlignment.end,
        ),
      ],
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
          Text('No hay ventas en este mes',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Probá con el mes anterior.',
            style: TextStyle(
                color: AppColors.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}
