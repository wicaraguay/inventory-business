import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:inventy_app/features/sales/domain/sale.dart';
import 'package:inventy_app/shared/format.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';

/// Bar chart of sales totals over time. [by] is 'day' or 'hour' (for labels).
class SalesChart extends StatelessWidget {
  const SalesChart({required this.buckets, required this.by, super.key});

  final List<SalesBucket> buckets;
  final String by;

  String _label(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final l = d.toLocal();
    return by == 'hour' ? '${two(l.hour)}h' : '${two(l.day)}/${two(l.month)}';
  }

  static String _shortMoney(double v) {
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(0)}k';
    return '\$${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) {
      return const Center(child: Text('Sin datos'));
    }
    final maxTotal =
        buckets.map((b) => b.total).fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = maxTotal <= 0 ? 10.0 : maxTotal * 1.25;
    final labelStep = by == 'hour' ? 3 : 2;

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              money(rod.toY),
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.divider, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) => Text(
                _shortMoney(value),
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= buckets.length || i % labelStep != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _label(buckets[i].bucket),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < buckets.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: buckets[i].total,
                  width: 14,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppColors.primary, Color(0xFF8B84F5)],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
