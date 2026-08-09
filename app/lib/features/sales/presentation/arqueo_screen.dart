import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/sales/domain/cash_close.dart';
import 'package:inventy_app/features/sales/presentation/cash_providers.dart';
import 'package:inventy_app/features/sales/presentation/sales_providers.dart';
import 'package:inventy_app/shared/format.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';
import 'package:inventy_app/shared/ui/app_alert.dart';

/// Cierre / arqueo de caja: compares the cash that SHOULD be in the drawer
/// (starting float + sales registered today) against what the owner counts,
/// flags any shortage, and can SAVE the close (history). Owner-only.
class ArqueoScreen extends ConsumerStatefulWidget {
  const ArqueoScreen({super.key});

  @override
  ConsumerState<ArqueoScreen> createState() => _ArqueoScreenState();
}

class _ArqueoScreenState extends ConsumerState<ArqueoScreen> {
  final _fondo = TextEditingController(text: '0');
  final _contado = TextEditingController();
  bool _saving = false;

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

  Future<void> _save(double ventasHoy) async {
    setState(() => _saving = true);
    try {
      await ref.read(cashRepositoryProvider).save(
            openingFloat: _num(_fondo),
            salesTotal: ventasHoy,
            counted: _num(_contado),
          );
      ref.invalidate(cashClosesProvider);
      if (mounted) {
        await showAppAlert(context,
            message: 'Cierre de caja guardado.', kind: AlertKind.success);
      }
    } on Object {
      if (mounted) {
        await showAppAlert(context,
            message: 'No se pudo guardar (revisá la conexión).',
            kind: AlertKind.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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
            'Al cerrar el día, contá el efectivo y compará con lo que el sistema '
            'espera. Guardá el cierre para tener el historial.',
            style: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 20),
          report.when(
            data: (r) => _body(context, r.summary.totalToday, _todayCount(r)),
            loading: () => const Center(
                child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator())),
            error: (e, _) => Text('No se pudieron cargar las ventas: $e'),
          ),
          const SizedBox(height: 24),
          _history(context),
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
    final counted = _num(_contado);
    final esperado = fondo + ventasHoy;
    final diff = counted - esperado;
    final hasCounted = _contado.text.trim().isNotEmpty;
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
                    helperText: 'Contá la plata de la caja y ponela acá',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (!hasCounted)
          Card(
            color: AppColors.primary.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ingresá el efectivo contado para ver si la caja cuadra.',
                      style: muted,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          _resultCard(esperado, counted, diff),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: (!hasCounted || _saving) ? null : () => _save(ventasHoy),
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_outlined),
          label: const Text('Guardar cierre'),
        ),
        const SizedBox(height: 8),
        Text(
          'Asume ventas en efectivo. Si cobraste con tarjeta o transferencia, '
          'restá esa parte del efectivo esperado.',
          style: TextStyle(
              fontSize: 12, color: AppColors.onSurface.withValues(alpha: 0.6)),
        ),
      ],
    );
  }

  Widget _resultCard(double esperado, double counted, double diff) {
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
            _line('Efectivo contado', money(counted)),
            const Divider(height: 20),
            Text(title,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(sub,
                style: TextStyle(
                    color: AppColors.onSurface.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }

  Widget _history(BuildContext context) {
    final closes = ref.watch(cashClosesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Cierres recientes',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        closes.when(
          data: (list) => list.isEmpty
              ? Text('Todavía no guardaste ningún cierre.',
                  style:
                      TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6)))
              : Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < list.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _closeRow(list[i]),
                      ],
                    ],
                  ),
                ),
          loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text('No se pudo cargar el historial: $e'),
        ),
      ],
    );
  }

  Widget _closeRow(CashClose c) {
    final ok = c.difference.abs() < 0.005;
    final color = ok
        ? AppColors.success
        : (c.difference < 0 ? AppColors.danger : AppColors.warning);
    final label = ok
        ? 'Cuadró'
        : (c.difference < 0
            ? 'Faltó ${money(-c.difference)}'
            : 'Sobró ${money(c.difference)}');
    final d = c.closedAt.toLocal();
    final fecha = '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
    return ListTile(
      title: Text('$fecha  ·  ${money(c.counted)} contado'),
      subtitle: Text(
        'Ventas ${money(c.salesTotal)} · fondo ${money(c.openingFloat)}'
        '${c.closedBy != null ? ' · ${c.closedBy}' : ''}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  }

  Widget _line(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  TextStyle(color: AppColors.onSurface.withValues(alpha: 0.7))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      );
}
