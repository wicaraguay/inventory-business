import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/dashboard/presentation/widgets/sales_chart.dart';
import 'package:inventy_app/features/sales/presentation/sales_providers.dart';
import 'package:inventy_app/shared/format.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';
import 'package:inventy_app/shared/ui/molecules/metric_card_row.dart';

/// Container: dashboard with sales totals, a sales chart, and low-stock alerts.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _by = 'day';
  DateTime _from = DateTime.now().subtract(const Duration(days: 29));
  DateTime _to = DateTime.now();

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _from : _to;
    final first = DateTime(2020);
    final last = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(last) ? last : initial,
      firstDate: first,
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

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(salesReportProvider);
    final series = ref.watch(salesSeriesProvider(_by));
    final rangeData = ref.watch(
      salesRangeProvider((from: _from, to: _to)),
    );
    final summary = report.asData?.value.summary;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Dashboard', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 4),
            Text(
              'Resumen de tus ventas',
              style:
                  TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            MetricCardRow([
              _RangeCard(
                label: 'Hoy',
                sales: summary?.totalToday ?? 0,
                profit: summary?.profitToday ?? 0,
              ),
              _RangeCard(
                label: '7 días',
                sales: summary?.totalWeek ?? 0,
                profit: summary?.profitWeek ?? 0,
              ),
              _RangeCard(
                label: 'Mes',
                sales: summary?.totalMonth ?? 0,
                profit: summary?.profitMonth ?? 0,
              ),
              _RangeCard(
                label: 'Trimestre',
                sales: summary?.totalQuarter ?? 0,
                profit: summary?.profitQuarter ?? 0,
              ),
              _RangeCard(
                label: 'Año',
                sales: summary?.totalYear ?? 0,
                profit: summary?.profitYear ?? 0,
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              'La ganancia es estimada: precio vendido menos el costo actual '
              'del proveedor.',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, c) {
                        final title = Text(
                          'Progreso de ventas',
                          style: Theme.of(context).textTheme.headlineMedium,
                        );
                        final toggle = SegmentedButton<String>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(value: 'day', label: Text('Por día')),
                            ButtonSegment(
                                value: 'hour', label: Text('Por hora')),
                          ],
                          selected: {_by},
                          onSelectionChanged: (s) =>
                              setState(() => _by = s.first),
                        );
                        if (c.maxWidth < 480) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              title,
                              const SizedBox(height: 12),
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: toggle),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: title),
                            toggle,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 240,
                      child: series.when(
                        data: (buckets) =>
                            SalesChart(buckets: buckets, by: _by),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ventas por período',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 240,
                      child: rangeData.when(
                        data: (buckets) =>
                            SalesChart(buckets: buckets, by: 'day'),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e')),
                      ),
                    ),
                    const SizedBox(height: 12),
                    rangeData.when(
                      data: (buckets) {
                        final total = buckets.fold<double>(
                            0, (sum, b) => sum + b.total);
                        return Text(
                          'Total del período: ${money(total)}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          textAlign: TextAlign.end,
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Presentational: button that shows a date and calls [onTap] when pressed.
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

/// One time-range tile: revenue on top, estimated profit below (green when
/// positive, red if you sold under cost).
class _RangeCard extends StatelessWidget {
  const _RangeCard({
    required this.label,
    required this.sales,
    required this.profit,
  });

  final String label;
  final double sales;
  final double profit;

  @override
  Widget build(BuildContext context) {
    final profitColor = profit >= 0 ? AppColors.success : AppColors.danger;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                money(sales),
                maxLines: 1,
                softWrap: false,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    profit >= 0 ? Icons.trending_up : Icons.trending_down,
                    size: 15,
                    color: profitColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${money(profit)} ganancia',
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      color: profitColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
