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

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(salesReportProvider);
    final series = ref.watch(salesSeriesProvider(_by));
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
          ],
        ),
      ),
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
