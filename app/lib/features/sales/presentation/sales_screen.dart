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

/// Container: the Ventas section — totals + sales history.
class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(salesReportProvider);
    final isOwner = ref.watch(currentUserProvider)?.isOwner ?? false;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          Expanded(
            child: report.when(
              data: (r) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MetricCardRow([
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
                  const SizedBox(height: 16),
                  Expanded(
                    child: r.records.isEmpty
                        ? const _Empty()
                        : SalesTable(
                            sales: r.records,
                            canVoid: isOwner,
                            onVoid: (s) => _confirmVoid(context, ref, s),
                          ),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmVoid(
      BuildContext context, WidgetRef ref, Sale sale) async {
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
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.point_of_sale,
              size: 48, color: AppColors.inputBorder),
          const SizedBox(height: 12),
          Text('Sin ventas todavía',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Registrá una venta escaneando un producto.',
            style: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}
