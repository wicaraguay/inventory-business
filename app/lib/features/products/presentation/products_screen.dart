import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/labels/data/label_printer.dart';
import 'package:inventy_app/features/labels/presentation/label_selection_provider.dart';
import 'package:inventy_app/features/scanning/presentation/identify_screen.dart';
import 'package:inventy_app/features/labels/presentation/label_sheet.dart';
import 'package:inventy_app/features/movements/domain/movement_repository.dart';
import 'package:inventy_app/features/movements/presentation/movements_providers.dart';
import 'package:inventy_app/features/movements/presentation/widgets/movement_sheet.dart';
import 'package:inventy_app/features/products/domain/bulk_product_input.dart';
import 'package:inventy_app/features/products/domain/product.dart';
import 'package:inventy_app/features/products/presentation/products_providers.dart';
import 'package:inventy_app/features/products/presentation/widgets/add_sizes_sheet.dart';
import 'package:inventy_app/features/products/presentation/widgets/bulk_create_sheet.dart';
import 'package:inventy_app/features/products/presentation/widgets/create_product_sheet.dart';
import 'package:inventy_app/features/products/presentation/widgets/product_detail_sheet.dart';
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
    // Owner OR an employee the owner enabled for inventory management.
    final canManage = ref.watch(currentUserProvider)?.canManage ?? false;
    final selection = ref.watch(labelSelectionProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selection.active)
            _SelectionBar(
              count: selection.ids.length,
              onCancel: () =>
                  ref.read(labelSelectionProvider.notifier).cancel(),
              onPrint: () => _printSelected(context, ref),
            )
          else
            _Header(
              count: products.asData?.value.length,
              owner: canManage,
              onAdd: () => _openBulkCreate(context, ref),
              onPrintAll: () => _printAll(context, ref),
              onSelect: () =>
                  ref.read(labelSelectionProvider.notifier).start(),
              onIdentify: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const IdentifyScreen()),
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: products.when(
              data: (items) => items.isEmpty
                  ? _Empty(canCreate: canManage)
                  : ProductTable(
                      products: items,
                      threshold: ref.watch(settingsProvider).defaultThreshold,
                      readOnly: !canManage,
                      selectionActive: selection.active,
                      selectedIds: selection.ids,
                      onToggleSelect: (product) => ref
                          .read(labelSelectionProvider.notifier)
                          .toggle(product.id),
                      onOpen: (product) => _openDetail(context, ref, product),
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

  Future<void> _openBulkCreate(BuildContext context, WidgetRef ref) async {
    final isOwner = ref.read(currentUserProvider)?.isOwner ?? false;
    final draft = await showModalBottomSheet<BulkDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BulkCreateSheet(showCost: isOwner),
    );
    if (draft == null) return;

    // Each size becomes its own flat product (sharing a model): SKU = prefix-size,
    // detail = "talle N" (+ color), initial stock = pairs of that size. The
    // low-stock threshold is global now, so it's the same for all.
    final threshold = ref.read(settingsProvider).defaultThreshold;
    final items = [
      for (final s in draft.sizes)
        BulkProductInput(
          name: draft.name,
          sku: '${draft.skuPrefix}-${s.size}',
          detail: draft.color == null
              ? 'talle ${s.size}'
              : 'talle ${s.size} · ${draft.color}',
          lowStockThreshold: threshold,
          salePrice: draft.salePrice,
          minPrice: draft.minPrice,
          supplierPrice: draft.supplierPrice,
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
      // Print one QR per pair (fixed 12-column format); warns if all are 0.
      if (context.mounted) {
        await _printLabels(context, created);
      }
    } on Object catch (e) {
      if (context.mounted) {
        await showAppAlert(context,
            message: '$e'.replaceFirst('Exception: ', ''),
            kind: AlertKind.error);
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

  /// Prints one QR per pair in stock and warns when there's nothing to label.
  Future<void> _printLabels(BuildContext context, List<Product> items) async {
    final printed = await printProductLabels(items);
    if (printed == 0 && context.mounted) {
      await showAppAlert(context,
          message: 'Estas tallas están en 0 — no hay pares para etiquetar. '
              'Cargá stock (Registrar Stock) y volvé a imprimir.',
          kind: AlertKind.info);
    }
  }

  Future<void> _printAll(BuildContext context, WidgetRef ref) async {
    final products = ref.read(productsProvider).asData?.value ?? const [];
    if (products.isEmpty) return;
    await _printLabels(context, products);
  }

  /// Print QR labels for just the products the user ticked. Same fixed
  /// 12-column format, so each QR is the same size as a full sheet.
  Future<void> _printSelected(BuildContext context, WidgetRef ref) async {
    final selection = ref.read(labelSelectionProvider);
    final all = ref.read(productsProvider).asData?.value ?? const <Product>[];
    final chosen = [for (final p in all) if (selection.ids.contains(p.id)) p];
    if (chosen.isEmpty) {
      await showAppAlert(context,
          message: 'Marcá al menos un producto para imprimir.',
          kind: AlertKind.info);
      return;
    }
    await _printLabels(context, chosen);
    ref.read(labelSelectionProvider.notifier).cancel();
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
        showCost: ref.read(currentUserProvider)?.isOwner ?? false,
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
            supplierPrice: result.supplierPrice,
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
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
          '¿Eliminar "${product.name}"? También se borran sus movimientos y '
          'ventas. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
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
    } on Object catch (e) {
      if (context.mounted) {
        await showAppAlert(context,
            message: 'No se pudo eliminar: $e', kind: AlertKind.error);
      }
    }
  }

  /// Tapping a product opens its detail: prices + every size of the same model
  /// with its stock. Siblings are grouped by modelId (falling back to name).
  void _openDetail(BuildContext context, WidgetRef ref, Product product) {
    final all = ref.read(productsProvider).asData?.value ?? const <Product>[];
    final siblings = [
      for (final p in all)
        if (product.modelId != null
            ? p.modelId == product.modelId
            : p.name == product.name)
          p,
    ];
    final isOwner = ref.read(currentUserProvider)?.isOwner ?? false;
    final threshold = ref.read(settingsProvider).defaultThreshold;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProductDetailSheet(
        product: product,
        siblings: siblings.isEmpty ? [product] : siblings,
        threshold: threshold,
        showCost: isOwner,
        onAddSizes:
            isOwner ? () => _openAddSizes(context, ref, product) : null,
      ),
    );
  }

  /// Add missing sizes to an EXISTING model: same model_id, prices, prefix and
  /// image are inherited; you only pick the new sizes. Owner-only (needs cost).
  Future<void> _openAddSizes(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final modelId = product.modelId;
    if (modelId == null) {
      await showAppAlert(context,
          message: 'Este producto no tiene un modelo asociado.',
          kind: AlertKind.error);
      return;
    }
    final newSizes = await showModalBottomSheet<List<BulkSizeDraft>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddSizesSheet(modelName: product.name),
    );
    if (newSizes == null || newSizes.isEmpty) return;

    // Inherit the SKU prefix and colour from the tapped size so the new ones
    // match the series exactly (SKU = prefix-size, detail = "talle N · color").
    final dash = product.sku.lastIndexOf('-');
    final prefix = dash >= 0 ? product.sku.substring(0, dash) : product.sku;
    final color = _colorFromDetail(product.detail);
    final threshold = ref.read(settingsProvider).defaultThreshold;
    final items = [
      for (final s in newSizes)
        BulkProductInput(
          name: product.name,
          sku: '$prefix-${s.size}',
          detail: color == null
              ? 'talle ${s.size}'
              : 'talle ${s.size} · $color',
          lowStockThreshold: threshold,
          salePrice: product.salePrice,
          minPrice: product.minPrice,
          supplierPrice: product.supplierPrice,
          initialStock: s.quantity,
        ),
    ];
    try {
      final created =
          await ref.read(productsProvider.notifier).addSizes(modelId, items);
      if (context.mounted) {
        await showAppAlert(context,
            message: '${created.length} talla(s) agregada(s) al modelo. '
                'Imprimí sus QR a continuación.',
            kind: AlertKind.success);
      }
      if (context.mounted) await _printLabels(context, created);
    } on Object catch (e) {
      if (context.mounted) {
        await showAppAlert(context,
            message: '$e'.replaceFirst('Exception: ', ''),
            kind: AlertKind.error);
      }
    }
  }

  /// Extracts the colour from a size detail like "talle 34 · Rojo".
  String? _colorFromDetail(String? detail) {
    if (detail == null) return null;
    final i = detail.indexOf('·');
    if (i < 0) return null;
    final c = detail.substring(i + 1).trim();
    return c.isEmpty ? null : c;
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
    required this.onAdd,
    required this.onPrintAll,
    required this.onSelect,
    required this.onIdentify,
  });

  final int? count;
  final bool owner;
  final VoidCallback onAdd;
  final VoidCallback onPrintAll;
  final VoidCallback onSelect;
  final VoidCallback onIdentify;

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

    // The one add flow: a model + its sizes (even one).
    final add = FilledButton.icon(
      onPressed: onAdd,
      icon: const Icon(Icons.add),
      label: const Text('Agregar producto'),
    );
    final printAll = OutlinedButton.icon(
      onPressed: hasProducts ? onPrintAll : null,
      icon: const Icon(Icons.qr_code_2),
      label: const Text('Imprimir etiquetas'),
    );
    // Pick a subset (e.g. just two shoes) and print only their QRs.
    final select = OutlinedButton.icon(
      onPressed: hasProducts ? onSelect : null,
      icon: const Icon(Icons.checklist),
      label: const Text('Elegir e imprimir'),
    );
    // Available to everyone: scan a printed QR to see which shoe/size it is.
    final identify = OutlinedButton.icon(
      onPressed: onIdentify,
      icon: const Icon(Icons.qr_code_scanner),
      label: const Text('Identificar QR'),
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 640) {
          // Phone: title, then full-width buttons ordered by importance.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleBlock,
              const SizedBox(height: 16),
              if (owner) ...[
                SizedBox(height: 48, child: add),
                const SizedBox(height: 8),
                SizedBox(height: 44, child: printAll),
                const SizedBox(height: 8),
                SizedBox(height: 44, child: select),
                const SizedBox(height: 8),
              ],
              SizedBox(height: 44, child: identify),
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
                children: [
                  identify,
                  if (owner) ...[select, printAll, add],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Replaces the header while picking products to print. Shows how many are
/// ticked, plus Cancel and "Imprimir (N)".
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.onCancel,
    required this.onPrint,
  });

  final int count;
  final VoidCallback onCancel;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onCancel,
          icon: const Icon(Icons.close),
          tooltip: 'Cancelar',
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            count == 0
                ? 'Marcá los productos a imprimir'
                : '$count seleccionado(s)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        FilledButton.icon(
          onPressed: count == 0 ? null : onPrint,
          icon: const Icon(Icons.qr_code_2),
          label: Text('Imprimir ($count)'),
        ),
      ],
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
          Icon(Icons.inventory_2_outlined,
              size: 48, color: AppColors.inputBorder),
          const SizedBox(height: 12),
          Text('No hay productos',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            canCreate
                ? 'Creá el primero con "Agregar producto".'
                : 'Todavía no hay productos cargados.',
            style: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}
