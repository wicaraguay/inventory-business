import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/auth/presentation/auth_providers.dart';
import 'package:inventy_app/features/products/domain/product.dart';
import 'package:inventy_app/shared/format.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';
import 'package:inventy_app/shared/ui/product_image.dart';

typedef CartInput = ({int quantity, double unitPrice});

/// Add a scanned/searched product to the current sale — or edit it if it's
/// already in the cart. Price policy: the OWNER can set any price down to the
/// minimum. An EMPLOYEE sells at the fixed list price; to go below it, an owner
/// must authorize the discount with their password.
class AddToCartSheet extends ConsumerStatefulWidget {
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
  ConsumerState<AddToCartSheet> createState() => _AddToCartSheetState();
}

class _AddToCartSheetState extends ConsumerState<AddToCartSheet> {
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

  // An owner authorized a discount on this line (unlocks the price field).
  bool _unlocked = false;
  String? _authorizedBy;

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

  Future<String?> _askOwnerPassword() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Autorizar descuento'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          autofocus: true,
          decoration:
              const InputDecoration(labelText: 'Contraseña del dueño'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text),
            child: const Text('Autorizar'),
          ),
        ],
      ),
    );
  }

  Future<void> _authorizeDiscount() async {
    final pass = await _askOwnerPassword();
    if (pass == null || pass.isEmpty) return;
    try {
      final by = await ref.read(authRepositoryProvider).authorizeDiscount(pass);
      if (!mounted) return;
      if (by == null) {
        _snack('Clave incorrecta');
        return;
      }
      setState(() {
        _unlocked = true;
        _authorizedBy = by;
      });
    } catch (_) {
      if (mounted) _snack('No se pudo verificar (revisá la conexión).');
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  /// A chip for one size of the model: label + stock. Muted/struck when out.
  Widget _sizeChip(ModelSize s) {
    final out = s.currentStock <= 0;
    final color =
        out ? AppColors.onSurface.withValues(alpha: 0.4) : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${s.label} · ${s.currentStock}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          decoration: out ? TextDecoration.lineThrough : null,
        ),
      ),
    );
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
    // The owner sets any price; an employee sells fixed unless a discount was
    // authorized in this sheet.
    final isOwner = ref.watch(currentUserProvider)?.isOwner ?? false;
    final canEditPrice = isOwner || _unlocked;

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
            // Other sizes of the same model (only when scanned).
            if (p.availableSizes.length > 1) ...[
              const SizedBox(height: 10),
              Text('Tallas del modelo:',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final s in p.availableSizes) _sizeChip(s)],
              ),
            ],
            const SizedBox(height: 12),
            // --- Price controls ---
            if (canEditPrice)
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
              )
            else
              Row(
                children: [
                  const Icon(Icons.lock_outline,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Precio fijo del negocio.',
                        style: TextStyle(
                            color:
                                AppColors.onSurface.withValues(alpha: 0.7))),
                  ),
                  TextButton.icon(
                    onPressed: _authorizeDiscount,
                    icon: const Icon(Icons.lock_open_outlined, size: 18),
                    label: const Text('Descuento'),
                  ),
                ],
              ),
            if (_authorizedBy != null) ...[
              const SizedBox(height: 6),
              Text('Descuento autorizado por $_authorizedBy',
                  style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ],
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
                      if (n > widget.maxQuantity) {
                        return 'Máx ${widget.maxQuantity}';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    readOnly: !canEditPrice,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Precio de venta',
                      suffixIcon: canEditPrice
                          ? null
                          : const Icon(Icons.lock_outline, size: 18),
                    ),
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
