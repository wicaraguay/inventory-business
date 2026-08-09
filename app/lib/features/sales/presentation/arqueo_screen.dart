import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/sales/presentation/sales_providers.dart';
import 'package:inventy_app/shared/format.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';

/// Cierre / arqueo de caja: compares the cash that SHOULD be in the drawer
/// (starting float + sales registered today) against what the owner counts, and
/// flags any shortage. Owner-only. A calculator over existing sales — no new
/// data is stored.
class ArqueoScreen extends ConsumerStatefulWidget {
  const ArqueoScreen({super.key});

  @override
  ConsumerState<ArqueoScreen> createState() => _ArqueoScreenState();
}

class _ArqueoScreenState extends ConsumerState<ArqueoScreen> {
  final _fondo = TextEditingController(text: '0');
  final _contado = TextEditingController();

  @override
  void dispose() {
    _fondo.dispose();
    _contado.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(salesReportProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          Text('Arqueo de caja',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text(
            'Compará el efectivo que debería haber con el que contás.',
            style: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 20),
          report.when(
            data: (r) => _body(context, r.summary.totalToday, _todayCount(r)),
            loading: () =>
                const Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator())),
            error: (e, _) => Text('No se pudieron cargar las ventas: $e'),
          ),
        ],
      ),
    );
  }

  int _todayCount(dynamic r) {
    final now = DateTime.now();
    return (r.records as List)
        .where((s) => _sameDay((s.createdAt as DateTime).toLocal(), now))
        .length;
  }

  Widget _body(BuildContext context, double ventasHoy, int countToday) {
    final fondo = _num(_fondo);
    final contado = _num(_contado);
    final esperado = fondo + ventasHoy;
    final diff = contado - esperado;
    final muted = TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Ventas registradas hoy',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(money(ventasHoy),
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w800)),
                Text('$countToday venta(s)', style: muted),
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
                TextField(
                  controller: _fondo,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Fondo inicial',
                    helperText: 'El efectivo con el que abriste la caja',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contado,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Efectivo contado ahora',
                    helperText: 'Lo que hay físicamente en la caja',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _resultCard(esperado, contado, diff),
        const SizedBox(height: 12),
        Text(
          'Asume ventas en efectivo. Si cobraste con tarjeta o transferencia, '
          'restá esa parte del efectivo esperado.',
          style: TextStyle(
              fontSize: 12, color: AppColors.onSurface.withValues(alpha: 0.6)),
        ),
      ],
    );
  }

  Widget _resultCard(double esperado, double contado, double diff) {
    final (color, title, sub) = switch (diff) {
      _ when diff.abs() < 0.005 => (
          AppColors.success,
          'Caja cuadra ✓',
          'El efectivo coincide con lo esperado.'
        ),
      _ when diff < 0 => (
          AppColors.danger,
          'Faltan ${money(-diff)}',
          'Hay menos efectivo del que debería. Revisá.'
        ),
      _ => (
          AppColors.warning,
          'Sobran ${money(diff)}',
          'Hay más efectivo del esperado.'
        ),
    };
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _line('Efectivo esperado', money(esperado)),
            const SizedBox(height: 4),
            _line('Efectivo contado', money(contado)),
            const Divider(height: 20),
            Text(title,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(sub,
                style:
                    TextStyle(color: AppColors.onSurface.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.7))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      );
}
