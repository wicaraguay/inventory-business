import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/labels/data/label_printer.dart';
import 'package:inventy_app/features/labels/presentation/label_sheet.dart';
import 'package:inventy_app/features/movements/domain/movement_repository.dart';
import 'package:inventy_app/features/movements/presentation/movements_providers.dart';
import 'package:inventy_app/features/movements/presentation/widgets/movement_sheet.dart';
import 'package:inventy_app/features/products/domain/bulk_product_input.dart';
import 'package:inventy_app/features/products/domain/product.dart';
import 'package:inventy_app/features/products/presentation/products_providers.dart';
import 'package:inventy_app/features/products/presentation/widgets/bulk_create_sheet.dart';
import 'package:inventy_app/features/products/presentation/widgets/create_product_sheet.dart';
import 'package:inventy_app/features/products/presentation/widgets/product_table.dart';
import 'package:inventy_app/features/auth/presentation/auth_providers.dart';
import 'package:inventy_app/features/settings/presentation/settings_providers.dart';
import 'package:inventy_app/shared/api/api_client.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';
import 'package:inventy_app/shared/ui/app_alert.dart';

/// Container: the Inventario section — a flat list of products.
class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final isOwner = ref.watch(currentUserProvider)?.isOwner ?? false;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            count: products.asData?.value.length,
            owner: isOwner,
            onCreate: () => _openCreate(context, ref),
            onBulkCreate: () => _openBulkCreate(context, ref),
            onPrintAll: () => _printAll(context, ref),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: products.when(
              data: (items) => items.isEmpty
                  ? _Empty(canCreate: isOwner)
                  : ProductTable(
                      products: items,
                      readOnly: !isOwner,
                      onMovement: (product, isEntry) =>
                          _openMovement(context, ref, product, isEntry),
                      onLabel: (product) => _openLabel(context, product),
                      onEdit: (product) => _openEdit(context, ref, product),
                      onDelete: (product) =>
                          _confirmDelete(context, ref, product),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreate(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<NewProduct>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateProductSheet(
        apiBaseUrl: ref.read(apiBaseUrlProvider),
        initialThreshold: ref.read(settingsProvider).defaultThreshold,
      ),
    );
    if (result == null) return;
    try {
      await ref.read(productsProvider.notifier).create(
            name: result.name,
            sku: result.sku,
            lowStockThreshold: result.threshold,
            detail: result.detail,
            salePrice: result.salePrice,
            minPrice: result.minPrice,
            initialStock: result.initialStock,
            imageBytes: result.imageBytes,
          );
    } on Exception catch (e) {
      if (context.mounted) {
        await showAppAlert(context,
            message: 'No se pudo crear: $e', kind: AlertKind.error);
      }
    }
  }

  Future<void> _openBulkCreate(BuildContext context, WidgetRef ref) async {
    final draft = await showModalBottomSheet<BulkDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BulkCreateSheet(
        initialThreshold: ref.read(settingsProvider).defaultThreshold,
      ),
    );
    if (draft == null) return;

    // Each size becomes its own flat product: SKU = prefix-size,
    // detail = "talle N" (+ color), initial stock = pairs of that size.
    final items = [
      for (final s in draft.sizes)
        BulkProductInput(
          name: draft.name,
          sku: '${draft.skuPrefix}-${s.size}',
          detail: draft.color == null
              ? 'talle ${s.size}'
              : 'talle ${s.size} · ${draft.color}',
          lowStockThreshold: draft.threshold,
          salePrice: draft.salePrice,
          minPrice: draft.minPrice,
          initialStock: s.quantity,
        ),
    ];

    try {
      final created =
          await ref.read(productsProvider.notifier).bulkCreate(items);
      // Apply the model image (if any) to every created size.
      if (draft.imageBytes != null) {
        final repo = ref.read(productRepositoryProvider);
        for (final p in created) {
          await repo.uploadImage(p.id, draft.imageBytes!);
        }
        ref.invalidate(productsProvider);
      }
      if (context.mounted) {
        await showAppAlert(
          context,
          message: '${created.length} tallas registradas. '
              'Imprimí sus etiquetas QR a continuación.',
          kind: AlertKind.success,
        );
      }
      // Print all the new labels in one PDF (one QR per size).
      if (context.mounted) {
        final columns = await _askLabelColumns(context);
        if (columns != null) {
          await printProductLabels(created, columns: columns);
        }
      }
    } on Exception catch (e) {
      if (context.mounted) {
        await showAppAlert(context,
            message: 'No se pudo cargar: $e', kind: AlertKind.error);
      }
    }
  }

  Future<void> _openMovement(
    BuildContext context,
    WidgetRef ref,
    Product product,
    bool isEntry,
  ) async {
    final input = await showModalBottomSheet<MovementInput>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MovementSheet(isEntry: isEntry, sku: product.name),
    );
    if (input == null) return;

    final repo = ref.read(movementRepositoryProvider);
    try {
      if (isEntry) {
        await repo.registerEntry(
            productId: product.id, quantity: input.quantity, note: input.note);
      } else {
        await repo.registerExit(
            productId: product.id, quantity: input.quantity, note: input.note);
      }
      ref.invalidate(productsProvider);
    } on MovementException catch (e) {
      if (context.mounted) {
        await showAppAlert(context, message: e.message, kind: AlertKind.error);
      }
    }
  }

  Future<void> _printAll(BuildContext context, WidgetRef ref) async {
    final products = ref.read(productsProvider).asData?.value ?? const [];
    if (products.isEmpty) return;
    final columns = await _askLabelColumns(context);
    if (columns == null) return;
    await printProductLabels(products, columns: columns);
  }

  /// Ask how many label columns per A4 sheet (more columns → smaller labels).
  Future<int?> _askLabelColumns(BuildContext context) {
    return showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('¿Cuántas columnas por hoja?'),
        children: [
          for (var c = 2; c <= maxLabelColumns; c++)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(c),
              child: Text('$c columnas   ·   ~${c * 9} etiquetas por hoja'),
            ),
        ],
      ),
    );
  }

  Future<void> _openEdit(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final result = await showModalBottomSheet<NewProduct>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateProductSheet(
        apiBaseUrl: ref.read(apiBaseUrlProvider),
        product: product,
      ),
    );
    if (result == null) return;
    try {
      await ref.read(productsProvider.notifier).edit(
            id: product.id,
            name: result.name,
            sku: result.sku,
            lowStockThreshold: result.threshold,
            detail: result.detail,
            salePrice: result.salePrice,
            minPrice: result.minPrice,
            imageBytes: result.imageBytes,
            removeImage: result.removeImage,
          );
    } on Exception catch (e) {
      if (context.mounted) {
        await showAppAlert(context,
            message: 'No se pudo guardar: $e', kind: AlertKind.error);
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
          '¿Eliminar "${product.name}"? También se borran sus movimientos y '
          'ventas. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(productsProvider.notifier).delete(product.id);
      if (context.mounted) {
        await showAppAlert(context,
            message: 'Producto eliminado.', kind: AlertKind.success);
      }
    } on Exception catch (e) {
      if (context.mounted) {
        await showAppAlert(context,
            message: 'No se pudo eliminar: $e', kind: AlertKind.error);
      }
    }
  }

  void _openLabel(BuildContext context, Product product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LabelSheet(product: product),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.count,
    required this.owner,
    required this.onCreate,
    required this.onBulkCreate,
    required this.onPrintAll,
  });

  final int? count;
  final bool owner;
  final VoidCallback onCreate;
  final VoidCallback onBulkCreate;
  final VoidCallback onPrintAll;

  @override
  Widget build(BuildContext context) {
    final hasProducts = (count ?? 0) > 0;

    final titleBlock = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Inventario', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 4),
        Text(
          count == null ? 'Gestioná tu stock' : '$count productos',
          style: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6)),
        ),
      ],
    );

    final newProduct = FilledButton.icon(
      onPressed: onCreate,
      icon: const Icon(Icons.add),
      label: const Text('Nuevo producto'),
    );
    final bulk = OutlinedButton.icon(
      onPressed: onBulkCreate,
      icon: const Icon(Icons.grid_view),
      label: const Text('Carga por tallas'),
    );
    final printAll = OutlinedButton.icon(
      onPressed: hasProducts ? onPrintAll : null,
      icon: const Icon(Icons.qr_code_2),
      label: const Text('Imprimir etiquetas'),
    );

    // Employees get a read-only inventory: just the title, no action buttons.
    if (!owner) return titleBlock;

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 640) {
          // Phone: title, then full-width buttons ordered by importance.
          // Big, aligned, easy-to-tap targets.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleBlock,
              const SizedBox(height: 16),
              SizedBox(height: 48, child: newProduct),
              const SizedBox(height: 8),
              SizedBox(height: 44, child: bulk),
              const SizedBox(height: 8),
              SizedBox(height: 44, child: printAll),
            ],
          );
        }
        // Wide: title on the left, actions on the right.
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleBlock,
            const SizedBox(width: 16),
            Expanded(
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [printAll, bulk, newProduct],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.canCreate});

  final bool canCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 48, color: AppColors.inputBorder),
          const SizedBox(height: 12),
          Text('No hay productos',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            canCreate
                ? 'Creá el primero con "Nuevo producto".'
                : 'Todavía no hay productos cargados.',
            style: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}
