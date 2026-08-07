import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final bell = IconButton(
      tooltip: 'Alertas de stock',
      icon: const Icon(Icons.notifications_outlined),
      onPressed: () => _open(context, ref),
    );
    return count == 0 ? bell : Badge.count(count: count, child: bell);
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
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: async.when(
        data: (items) => LowStockList(items: items),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
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
