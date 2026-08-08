import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/labels/data/label_printer.dart';
import 'package:inventy_app/features/scanning/presentation/identify_screen.dart';
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
    // Owner OR an employee the owner enabled for inventory management.
    final canManage = ref.watch(currentUserProvider)?.canManage ?? false;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            count: products.asData?.value.length,
            owner: canManage,
            onCreate: () => _openCreate(context, ref),
            onBulkCreate: () => _openBulkCreate(context, ref),
            onPrintAll: () => _printAll(context, ref),
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
        final opts = await _askLabelOptions(context);
        if (opts != null) {
          await printProductLabels(created,
              columns: opts.columns, showText: opts.withText);
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
    final opts = await _askLabelOptions(context);
    if (opts == null) return;
    await printProductLabels(products,
        columns: opts.columns, showText: opts.withText);
  }

  /// Ask the label format: how many columns per A4 sheet, and whether to include
  /// the product data (off by default → QR-only labels).
  Future<({int columns, bool withText})?> _askLabelOptions(
    BuildContext context,
  ) {
    var withText = false;
    return showDialog<({int columns, bool withText})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => SimpleDialog(
          title: const Text('Imprimir etiquetas'),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: withText,
                onChanged: (v) => setState(() => withText = v ?? false),
                title: const Text('Incluir nombre y talla'),
                subtitle: const Text('Por defecto: solo el QR'),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: Text(
                '¿Cuántas columnas por hoja?',
                style: Theme.of(ctx).textTheme.labelLarge,
              ),
            ),
            for (var c = 2;
                c <= (withText ? maxLabelColumns : maxLabelColumnsQrOnly);
                c++)
              SimpleDialogOption(
                onPressed: () => Navigator.of(ctx)
                    .pop((columns: c, withText: withText)),
                child: Text('$c columnas   ·   ~${c * 9} etiquetas por hoja'),
              ),
          ],
        ),
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
    debugPrint('🗑️ [1] click Eliminar -> id=${product.id} name=${product.name}');
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
            onPressed: () {
              debugPrint('🗑️ [1b] click CANCELAR en el diálogo');
              Navigator.of(dialogCtx).pop(false);
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              debugPrint('🗑️ [1b] click ELIMINAR (confirmar) en el diálogo');
              Navigator.of(dialogCtx).pop(true);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    debugPrint('🗑️ [2] confirmación del diálogo = $ok');
    if (ok != true) return;
    try {
      debugPrint('🗑️ [3] llamando notifier.delete...');
      await ref.read(productsProvider.notifier).delete(product.id);
      debugPrint('🗑️ [4] notifier.delete OK (sin error)');
      if (context.mounted) {
        await showAppAlert(context,
            message: 'Producto eliminado.', kind: AlertKind.success);
      }
    } on Object catch (e, st) {
      debugPrint('🔴 [X] ERROR al borrar: $e');
      debugPrint('$st');
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
    required this.onIdentify,
  });

  final int? count;
  final bool owner;
  final VoidCallback onCreate;
  final VoidCallback onBulkCreate;
  final VoidCallback onPrintAll;
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
          // Big, aligned, easy-to-tap targets.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleBlock,
              const SizedBox(height: 16),
              if (owner) ...[
                SizedBox(height: 48, child: newProduct),
                const SizedBox(height: 8),
                SizedBox(height: 44, child: bulk),
                const SizedBox(height: 8),
                SizedBox(height: 44, child: printAll),
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
                  if (owner) ...[printAll, bulk, newProduct],
                ],
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
          Icon(Icons.inventory_2_outlined,
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
