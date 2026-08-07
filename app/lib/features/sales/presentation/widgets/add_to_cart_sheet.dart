import 'package:flutter/material.dart';
import 'package:inventy_app/features/products/domain/product.dart';
import 'package:inventy_app/shared/format.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';
import 'package:inventy_app/shared/ui/product_image.dart';

typedef CartInput = ({int quantity, double unitPrice});

/// Add a scanned/searched product to the current sale — or edit it if it's
/// already in the cart. The price is prefilled (normal, or the current line's
/// price when editing) and can't go below the minimum. Quick chips switch
/// between the normal and minimum price in one tap.
class AddToCartSheet extends StatefulWidget {
  const AddToCartSheet({
    required this.product,
    required this.maxQuantity,
    this.initialQuantity = 1,
    this.initialPrice,
    this.alreadyInCart = false,
    super.key,
  });

  final Product product;
  final int maxQuantity;
  final int initialQuantity;
  final double? initialPrice;
  final bool alreadyInCart;

  @override
  State<AddToCartSheet> createState() => _AddToCartSheetState();
}

class _AddToCartSheetState extends State<AddToCartSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _quantity =
      TextEditingController(text: '${widget.initialQuantity}');
  late final _price = TextEditingController(
    text: (widget.initialPrice ??
            widget.product.salePrice ??
            widget.product.minPrice ??
            0)
        .toStringAsFixed(2),
  );

  void _setPrice(double value) {
    _price.text = value.toStringAsFixed(2);
    _formKey.currentState?.validate();
  }

  @override
  void dispose() {
    _quantity.dispose();
    _price.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      quantity: int.parse(_quantity.text.trim()),
      unitPrice: double.parse(_price.text.trim().replaceAll(',', '.')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final min = p.minPrice;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductThumbnail(product: p, size: 72),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: Theme.of(context).textTheme.headlineMedium),
                      if (p.detail != null) Text(p.detail!),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.alreadyInCart) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Este producto ya está en la venta. '
                        'Modificá la cantidad o el precio.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text('Disponible: ${widget.maxQuantity}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            // One-tap price switch (e.g. lower to the minimum for a customer).
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (p.salePrice != null)
                  ActionChip(
                    avatar: const Icon(Icons.sell_outlined, size: 16),
                    label: Text('Normal ${money(p.salePrice)}'),
                    onPressed: () => _setPrice(p.salePrice!),
                  ),
                if (p.minPrice != null)
                  ActionChip(
                    avatar: const Icon(Icons.trending_down, size: 16),
                    label: Text('Mínimo ${money(p.minPrice)}'),
                    onPressed: () => _setPrice(p.minPrice!),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 110,
                  child: TextFormField(
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());
                      if (n == null || n <= 0) return 'Inválida';
                      if (n > widget.maxQuantity) return 'Máx ${widget.maxQuantity}';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Precio de venta'),
                    validator: (v) {
                      final n = double.tryParse(
                          (v ?? '').trim().replaceAll(',', '.'));
                      if (n == null || n < 0) return 'Precio inválido';
                      if (min != null && n < min) {
                        return 'No puede ser menor a ${money(min)}';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _submit,
              icon: Icon(widget.alreadyInCart
                  ? Icons.check
                  : Icons.add_shopping_cart),
              label: Text(widget.alreadyInCart
                  ? 'Actualizar en la venta'
                  : 'Agregar a la venta'),
            ),
          ],
        ),
      ),
    );
  }
}
