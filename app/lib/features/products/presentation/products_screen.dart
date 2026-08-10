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
    final query = ref.watch(productSearchProvider).trim().toLowerCase();
    final hasProducts = products.asData?.value.isNotEmpty ?? false;
    // Web: the search sits inside the header toolbar. App: a full-width field
    // below the header (no extra button). Only shown when there's something
    // to search and we're not picking labels.
    final wide = MediaQuery.sizeOf(context).width >= 640;
    final showSearch = hasProducts && !selection.active;

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
              onPrintPending: () => _printPending(context, ref),
              onSelect: () =>
                  ref.read(labelSelectionProvider.notifier).start(),
              onIdentify: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const IdentifyScreen()),
              ),
              // Web only: inline search in the toolbar.
              search: (wide && showSearch)
                  ? const _InventorySearch(key: ValueKey('search-web'))
                  : null,
            ),
          // App only: full-width search below the header.
          if (!wide && showSearch) ...[
            const SizedBox(height: 12),
            const _InventorySearch(key: ValueKey('search-app')),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: products.when(
              data: (items) {
                if (items.isEmpty) return _Empty(canCreate: canManage);
                final filtered = query.isEmpty
                    ? items
                    : [
                        for (final p in items)
                          if (p.name.toLowerCase().contains(query) ||
                              (p.detail ?? '').toLowerCase().contains(query) ||
                              p.sku.toLowerCase().contains(query))
                            p,
                      ];
                if (filtered.isEmpty) return _NoResults(query: query);
                return ProductTable(
                  products: filtered,
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
                  onDelete: (product) => _confirmDelete(context, ref, product),
                  onMarkLabeled: (product, labeled) => ref
                      .read(productsProvider.notifier)
                      .markLabeled([product.id], labeled: labeled),
                );
              },
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
      showDragHandle: true,
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
              ? 'Talla ${s.size}'
              : 'Talla ${s.size} · ${draft.color}',
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
      // Print one QR per pair, then offer to mark the new batch as labeled.
      if (context.mounted) {
        await _printAndOfferMark(context, ref, created);
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
      showDragHandle: true,
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

  /// Prints one QR per pair in stock; then — only if any printed product was
  /// still pending — asks whether they were ACTUALLY printed+applied (generating
  /// the PDF is not the same as printing) and marks them labeled if confirmed.
  Future<void> _printAndOfferMark(
    BuildContext context,
    WidgetRef ref,
    List<Product> items,
  ) async {
    final printed = await printProductLabels(items);
    if (!context.mounted) return;
    if (printed == 0) {
      await showAppAlert(context,
          message: 'Estas tallas están en 0 — no hay pares para etiquetar. '
              'Cargá stock (Registrar Stock) y volvé a imprimir.',
          kind: AlertKind.info);
      return;
    }
    final pendingIds = [for (final p in items) if (!p.labeled) p.id];
    if (pendingIds.isEmpty) return; // a reprint of already-labeled items
    final done = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.print_outlined,
            color: AppColors.primary, size: 40),
        title: const Text('¿Ya las imprimiste?'),
        content: Text(
          'Generé el PDF con las etiquetas. ¿Ya imprimiste y pegaste las de '
          'los ${pendingIds.length} producto(s) nuevos?\n\n'
          'Si solo estabas verificando el PDF, elegí "Todavía no" y siguen '
          'pendientes.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Todavía no')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sí, marcarlas')),
        ],
      ),
    );
    if (done == true) {
      await ref
          .read(productsProvider.notifier)
          .markLabeled(pendingIds, labeled: true);
      if (context.mounted) {
        await showAppAlert(context,
            message: '${pendingIds.length} producto(s) marcados como '
                'etiquetados.',
            kind: AlertKind.success);
      }
    }
  }

  /// Prints ONLY the pending labels (registered but not yet labeled, with stock)
  /// so re-labeling never re-prints what's already done.
  Future<void> _printPending(BuildContext context, WidgetRef ref) async {
    final all = ref.read(productsProvider).asData?.value ?? const <Product>[];
    final pending = [
      for (final p in all)
        if (!p.labeled && p.currentStock > 0) p,
    ];
    final pendingNoStock =
        all.where((p) => !p.labeled && p.currentStock <= 0).length;
    if (pending.isEmpty) {
      await showAppAlert(context,
          message: pendingNoStock > 0
              ? 'No hay etiquetas pendientes con stock. Tenés $pendingNoStock '
                  'talla(s) sin etiqueta pero en 0 — cargá stock y volvé.'
              : 'No hay etiquetas pendientes: todo tu inventario ya está '
                  'etiquetado. Para reimprimir alguna, usá "Elegir e imprimir".',
          kind: AlertKind.info);
      return;
    }
    await _printAndOfferMark(context, ref, pending);
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
    await _printAndOfferMark(context, ref, chosen);
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
      showDragHandle: true,
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
      showDragHandle: true,
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
      showDragHandle: true,
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
              ? 'Talla ${s.size}'
              : 'Talla ${s.size} · $color',
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
      if (context.mounted) await _printAndOfferMark(context, ref, created);
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
      showDragHandle: true,
      builder: (_) => LabelSheet(product: product),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.count,
    required this.owner,
    required this.onAdd,
    required this.onPrintPending,
    required this.onSelect,
    required this.onIdentify,
    this.search,
  });

  final int? count;
  final bool owner;
  final VoidCallback onAdd;
  final VoidCallback onPrintPending;
  final VoidCallback onSelect;
  final VoidCallback onIdentify;

  /// Web only: an inline search field placed in the actions toolbar.
  final Widget? search;

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
    final printPending = OutlinedButton.icon(
      onPressed: hasProducts ? onPrintPending : null,
      icon: const Icon(Icons.qr_code_2),
      label: const Text('Imprimir pendientes'),
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
                SizedBox(height: 44, child: printPending),
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
                  if (search != null) SizedBox(width: 240, child: search),
                  identify,
                  if (owner) ...[select, printPending, add],
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

/// Always-visible inline search field (NOT a button). Filters the list live by
/// name, size or SKU. Its controller seeds from the shared query so swapping
/// between the web (toolbar) and app (below header) spots keeps the text.
class _InventorySearch extends ConsumerStatefulWidget {
  const _InventorySearch({super.key});

  @override
  ConsumerState<_InventorySearch> createState() => _InventorySearchState();
}

class _InventorySearchState extends ConsumerState<_InventorySearch> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(productSearchProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(productSearchProvider);
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      onChanged: (v) => ref.read(productSearchProvider.notifier).set(v),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Buscar por nombre, talla o código',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpiar',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  _controller.clear();
                  ref.read(productSearchProvider.notifier).set('');
                },
              ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// Shown when a search matches nothing (there ARE products, just not these).
class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48, color: AppColors.inputBorder),
          const SizedBox(height: 12),
          Text('Sin resultados',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'No hay productos que coincidan con "$query".',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}
