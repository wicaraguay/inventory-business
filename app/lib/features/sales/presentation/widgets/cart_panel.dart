import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/sales/presentation/cart_providers.dart';
import 'package:inventy_app/features/sales/presentation/widgets/add_to_cart_sheet.dart';
import 'package:inventy_app/features/sales/presentation/widgets/quick_sale_sheet.dart';
import 'package:inventy_app/shared/format.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';
import 'package:inventy_app/shared/ui/product_image.dart';

/// The current sale: cart lines (inventory + quick) + total + "Realizar venta".
class CartPanel extends ConsumerWidget {
  const CartPanel({required this.onCheckout, super.key});

  final Future<void> Function() onCheckout;

  /// Edit an inventory product line.
  Future<void> _editProductLine(
    BuildContext context,
    WidgetRef ref,
    CartLine line,
    int index,
  ) async {
    final product = line.product!;
    final input = await showModalBottomSheet<CartInput>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddToCartSheet(
        product: product,
        maxQuantity: product.currentStock,
        initialQuantity: line.quantity,
        initialPrice: line.unitPrice,
        alreadyInCart: true,
      ),
    );
    if (input == null) return;
    ref.read(cartProvider.notifier).updateAt(index, input.quantity, input.unitPrice);
  }

  /// Edit a quick-sale line.
  Future<void> _editQuickLine(
    BuildContext context,
    WidgetRef ref,
    CartLine line,
    int index,
  ) async {
    final input = await showModalBottomSheet<QuickSaleInput>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => QuickSaleSheet(
        initialQuantity: line.quantity,
        initialTotal: line.explicitTotal,
        initialDescription: line.description ?? '',
        initialSizeLabel: line.sizeLabel ?? '',
        initialDate: line.date,
        isEditing: true,
      ),
    );
    if (input == null) return;
    ref.read(cartProvider.notifier).updateQuickAt(
          index,
          quantity: input.quantity,
          total: input.total,
          description: input.description,
          sizeLabel: input.sizeLabel,
          date: input.date,
        );
  }

  Widget _inventoryTile(
    BuildContext context,
    WidgetRef ref,
    CartLine line,
    int index,
  ) {
    final p = line.product!;
    final name = p.detail == null ? p.name : '${p.name} · ${p.detail}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => _editProductLine(context, ref, line, index),
      leading: ProductThumbnail(product: p, size: 40),
      title:
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${line.quantity} × ${money(line.unitPrice)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(money(line.subtotal),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () =>
                ref.read(cartProvider.notifier).removeAt(index),
          ),
        ],
      ),
    );
  }

  Widget _quickTile(
    BuildContext context,
    WidgetRef ref,
    CartLine line,
    int index,
  ) {
    final subtitle = [
      '${line.quantity} par${line.quantity != 1 ? 'es' : ''}',
      if (line.sizeLabel != null && line.sizeLabel!.isNotEmpty)
        'talla ${line.sizeLabel}',
      if (line.date != null)
        '${line.date!.day}/${line.date!.month}/${line.date!.year}',
    ].join(' · ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => _editQuickLine(context, ref, line, index),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.shopping_bag_outlined,
            size: 20, color: AppColors.primary),
      ),
      title: Text(
        line.description ?? 'Venta rápida',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(money(line.subtotal),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () =>
                ref.read(cartProvider.notifier).removeAt(index),
          ),
        ],
      ),
    );
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
                        'Completá una venta rápida\no escaneá un producto.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              AppColors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: cart.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final line = cart[i];
                        return line.isQuick
                            ? _quickTile(context, ref, line, i)
                            : _inventoryTile(context, ref, line, i);
                      },
                    ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total',
                    style: Theme.of(context).textTheme.titleLarge),
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
