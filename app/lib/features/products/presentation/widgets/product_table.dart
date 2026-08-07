import 'package:flutter/material.dart';
import 'package:inventy_app/features/products/domain/product.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';
import 'package:inventy_app/shared/ui/atoms/status_pill.dart';
import 'package:inventy_app/shared/ui/product_image.dart';

/// Presentational: the flat products list. A real table on wide screens; a
/// stack of cards on phones (where fixed columns wouldn't fit).
class ProductTable extends StatelessWidget {
  const ProductTable({
    required this.products,
    required this.onMovement,
    required this.onLabel,
    required this.onEdit,
    required this.onDelete,
    this.readOnly = false,
    super.key,
  });

  final List<Product> products;
  final void Function(Product product, bool isEntry) onMovement;
  final void Function(Product product) onLabel;
  final void Function(Product product) onEdit;
  final void Function(Product product) onDelete;

  /// Employees see stock but cannot act on it: no per-row actions menu.
  final bool readOnly;

  StockStatus _status(Product p) {
    if (p.currentStock <= 0) return StockStatus.out;
    if (p.currentStock <= p.lowStockThreshold) return StockStatus.low;
    return StockStatus.inStock;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 640;
        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!narrow) ...[
                const _HeaderRow(),
                const Divider(height: 1),
              ],
              Expanded(
                child: ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final product = products[i];
                    final menu = readOnly
                        ? const SizedBox(width: 48)
                        : _RowMenu(
                            product: product,
                            onMovement: onMovement,
                            onLabel: onLabel,
                            onEdit: onEdit,
                            onDelete: onDelete,
                          );
                    return narrow
                        ? _MobileRow(
                            product: product,
                            status: _status(product),
                            zebra: i.isOdd,
                            menu: menu,
                          )
                        : _DataRow(
                            product: product,
                            status: _status(product),
                            zebra: i.isOdd,
                            menu: menu,
                          );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.onSurface.withValues(alpha: 0.6),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('PRODUCTO', style: labelStyle)),
          Expanded(flex: 3, child: Text('DETALLE', style: labelStyle)),
          SizedBox(width: 70, child: Text('STOCK', style: labelStyle)),
          SizedBox(width: 120, child: Text('ESTADO', style: labelStyle)),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/// Phone layout: thumbnail + name/detail/sku + status & stock + actions menu.
class _MobileRow extends StatelessWidget {
  const _MobileRow({
    required this.product,
    required this.status,
    required this.zebra,
    required this.menu,
  });

  final Product product;
  final StockStatus status;
  final bool zebra;
  final Widget menu;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.onSurface.withValues(alpha: 0.6);
    return Container(
      color: zebra ? AppColors.canvas : AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      child: Row(
        children: [
          ProductThumbnail(product: product, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (product.detail != null && product.detail!.isNotEmpty)
                  Text(
                    product.detail!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    StatusPill(status),
                    const SizedBox(width: 8),
                    Text(
                      'Stock ${product.currentStock}',
                      style: TextStyle(
                          color: muted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          menu,
        ],
      ),
    );
  }
}

/// Wide layout: one fixed-column row.
class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.product,
    required this.status,
    required this.zebra,
    required this.menu,
  });

  final Product product;
  final StockStatus status;
  final bool zebra;
  final Widget menu;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: zebra ? AppColors.canvas : AppColors.surface,
      padding: const EdgeInsets.only(left: 20, right: 4),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                ProductThumbnail(product: product, size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    product.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.detail != null)
                  Text(
                    product.detail!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppColors.onSurface.withValues(alpha: 0.7)),
                  ),
                Text(
                  product.sku,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppColors.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              '${product.currentStock}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(width: 120, child: StatusPill(status)),
          menu,
        ],
      ),
    );
  }
}

class _RowMenu extends StatelessWidget {
  const _RowMenu({
    required this.product,
    required this.onMovement,
    required this.onLabel,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final void Function(Product product, bool isEntry) onMovement;
  final void Function(Product product) onLabel;
  final void Function(Product product) onEdit;
  final void Function(Product product) onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: AppColors.onSurface),
        onSelected: (action) => switch (action) {
          'entry' => onMovement(product, true),
          'exit' => onMovement(product, false),
          'label' => onLabel(product),
          'edit' => onEdit(product),
          _ => onDelete(product),
        },
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'entry',
            child: ListTile(
              leading: Icon(Icons.add, color: AppColors.success),
              title: Text('Registrar entrada'),
            ),
          ),
          PopupMenuItem(
            value: 'exit',
            child: ListTile(
              leading: Icon(Icons.remove, color: AppColors.danger),
              title: Text('Registrar salida'),
            ),
          ),
          PopupMenuItem(
            value: 'label',
            child: ListTile(
              leading: Icon(Icons.qr_code_2),
              title: Text('Imprimir etiqueta QR'),
            ),
          ),
          PopupMenuDivider(),
          PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text('Editar'),
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.danger),
              title: Text('Eliminar'),
            ),
          ),
        ],
      ),
    );
  }
}
