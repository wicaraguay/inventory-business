import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/dashboard/presentation/widgets/sales_chart.dart';
import 'package:inventy_app/features/sales/presentation/sales_providers.dart';
import 'package:inventy_app/shared/format.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';
import 'package:inventy_app/shared/ui/molecules/metric_card.dart';
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
              MetricCard(
                label: 'Ventas hoy',
                value: money(summary?.totalToday),
                icon: Icons.point_of_sale,
                accent: AppColors.success,
              ),
              MetricCard(
                label: 'Ventas del mes',
                value: money(summary?.totalMonth),
                icon: Icons.calendar_month_outlined,
              ),
              MetricCard(
                label: 'Ventas del año',
                value: money(summary?.totalYear),
                icon: Icons.insights_outlined,
              ),
            ]),
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
