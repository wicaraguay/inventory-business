import 'package:flutter/material.dart';
import 'package:inventy_app/features/products/domain/product.dart';
import 'package:inventy_app/shared/format.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';
import 'package:inventy_app/shared/ui/atoms/status_pill.dart';
import 'package:inventy_app/shared/ui/product_image.dart';

/// Presentational: a model's detail — image, prices, and EVERY size of the same
/// model with its stock. Opened by tapping a product row. Pure props-in.
class ProductDetailSheet extends StatelessWidget {
  const ProductDetailSheet({
    required this.product,
    required this.siblings,
    required this.threshold,
    this.showCost = false,
    super.key,
  });

  /// The tapped product (its prices/image represent the model).
  final Product product;

  /// All sizes of the same model (including [product]).
  final List<Product> siblings;

  /// Global low-stock threshold, to color each size.
  final int threshold;

  /// Whether to show the supplier (cost) price — owner only.
  final bool showCost;

  StockStatus _status(int stock) {
    if (stock <= 0) return StockStatus.out;
    if (stock <= threshold) return StockStatus.low;
    return StockStatus.inStock;
  }

  /// Numeric size parsed from the SKU suffix (…-41) so sizes sort naturally.
  int _sizeKey(Product p) {
    final dash = p.sku.lastIndexOf('-');
    final tail = dash >= 0 ? p.sku.substring(dash + 1) : p.sku;
    return int.tryParse(tail.trim()) ?? 1 << 30;
  }

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6));
    final sizes = [...siblings]..sort((a, b) => _sizeKey(a).compareTo(_sizeKey(b)));
    final totalStock = sizes.fold<int>(0, (a, p) => a + p.currentStock);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductThumbnail(product: product, size: 72),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text('${sizes.length} tallas · $totalStock en stock',
                            style: muted),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _priceChip('Precio de venta', product.salePrice,
                      AppColors.primary),
                  _priceChip('Precio mínimo', product.minPrice,
                      AppColors.onSurface),
                  if (showCost && product.supplierPrice != null)
                    _priceChip('Costo (proveedor)', product.supplierPrice,
                        AppColors.warning),
                ],
              ),
              const SizedBox(height: 20),
              Text('Tallas y stock',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: sizes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => _sizeRow(sizes[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceChip(String label, double? value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 2),
          Text(value == null ? '—' : money(value),
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _sizeRow(Product p) {
    final label = (p.detail == null || p.detail!.isEmpty) ? p.sku : p.detail!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Text('${p.currentStock}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(width: 12),
          StatusPill(_status(p.currentStock)),
        ],
      ),
    );
  }
}
