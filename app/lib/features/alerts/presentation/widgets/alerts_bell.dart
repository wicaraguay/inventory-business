import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventy_app/features/alerts/presentation/alerts_providers.dart';
import 'package:inventy_app/features/auth/presentation/auth_providers.dart';
import 'package:inventy_app/features/dashboard/presentation/dashboard_providers.dart';
import 'package:inventy_app/features/dashboard/presentation/widgets/low_stock_list.dart';

/// A bell with a live count of products at/below their stock threshold. Only
/// shown to users who can manage inventory (owner + enabled employees) and only
/// when in-app alerts are enabled on this device. Tapping opens the full list.
class AlertsBell extends ConsumerWidget {
  const AlertsBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage = ref.watch(currentUserProvider)?.canManage ?? false;
    final enabled = ref.watch(alertsEnabledProvider);
    // Don't even fetch /alerts for users who shouldn't see it.
    if (!canManage || !enabled) return const SizedBox.shrink();

    final count = ref.watch(lowStockProvider).asData?.value.length ?? 0;
    // Badge wraps the ICON (not the 48px button) so the number hugs the bell.
    const icon = Icon(Icons.notifications_outlined);
    return IconButton(
      tooltip: 'Alertas de stock',
      onPressed: () => _open(context, ref),
      icon: count == 0 ? icon : Badge.count(count: count, child: icon),
    );
  }

  void _open(BuildContext context, WidgetRef ref) {
    // Pull fresh so the list reflects the latest sales.
    ref.invalidate(lowStockProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AlertsSheet(),
    );
  }
}

class _AlertsSheet extends ConsumerWidget {
  const _AlertsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(lowStockProvider);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: async.when(
          data: (items) => LowStockList(
            items: items,
            shrinkWrap: true,
            onTap: (_) {
              // Close the sheet and jump to the inventory to fix the stock.
              Navigator.of(context).pop();
              context.go('/inventory');
            },
            onDismiss: (item) async {
              await ref
                  .read(dashboardRepositoryProvider)
                  .snoozeAlert(item.productId);
              ref.invalidate(lowStockProvider);
            },
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No se pudieron cargar las alertas.\n$e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
