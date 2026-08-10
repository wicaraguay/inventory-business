import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/sales/presentation/cart_providers.dart';
import 'package:inventy_app/features/sales/presentation/widgets/add_to_cart_sheet.dart';
import 'package:inventy_app/shared/format.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';
import 'package:inventy_app/shared/ui/product_image.dart';

/// The current sale: cart lines + total + "Realizar venta".
class CartPanel extends ConsumerWidget {
  const CartPanel({required this.onCheckout, super.key});

  final Future<void> Function() onCheckout;

  /// Tapping a line reopens the add sheet in edit mode (change qty or price).
  Future<void> _editLine(
    BuildContext context,
    WidgetRef ref,
    CartLine line,
  ) async {
    final input = await showModalBottomSheet<CartInput>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddToCartSheet(
        product: line.product,
        maxQuantity: line.product.currentStock,
        initialQuantity: line.quantity,
        initialPrice: line.unitPrice,
        alreadyInCart: true,
      ),
    );
    if (input == null) return;
    final notifier = ref.read(cartProvider.notifier);
    final idx = notifier.indexOf(line.product.id);
    if (idx != -1) notifier.updateAt(idx, input.quantity, input.unitPrice);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final total = cart.fold<double>(0, (s, l) => s + l.subtotal);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Venta actual',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Expanded(
              child: cart.isEmpty
                  ? Center(
                      child: Text(
                        'Escaneá o buscá un producto\npara agregarlo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: cart.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final line = cart[i];
                        final name = line.product.detail == null
                            ? line.product.name
                            : '${line.product.name} · ${line.product.detail}';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          onTap: () => _editLine(context, ref, line),
                          leading: ProductThumbnail(
                              product: line.product, size: 40),
                          title: Text(name,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                              '${line.quantity} × ${money(line.unitPrice)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(money(line.subtotal),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => ref
                                    .read(cartProvider.notifier)
                                    .removeAt(i),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: Theme.of(context).textTheme.titleLarge),
                Text(money(total),
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: cart.isEmpty ? null : onCheckout,
              icon: const Icon(Icons.point_of_sale),
              label: const Text('Realizar venta'),
            ),
          ],
        ),
      ),
    );
  }
}
