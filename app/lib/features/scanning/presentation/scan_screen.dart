import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventy_app/features/dashboard/presentation/dashboard_providers.dart';
import 'package:inventy_app/features/products/domain/product.dart';
import 'package:inventy_app/features/products/presentation/products_providers.dart';
import 'package:inventy_app/features/sales/domain/sale_repository.dart';
import 'package:inventy_app/features/sales/presentation/cart_providers.dart';
import 'package:inventy_app/features/sales/presentation/sales_providers.dart';
import 'package:inventy_app/features/sales/presentation/widgets/add_to_cart_sheet.dart';
import 'package:inventy_app/features/sales/presentation/widgets/cart_panel.dart';
import 'package:inventy_app/features/scanning/presentation/scanning_providers.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';
import 'package:inventy_app/shared/ui/app_alert.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Point of sale: scan OR search (by name/code) products into a cart, then sell.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  // We only use our own QR labels (they encode the product SKU).
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- Scanner path: resolve the exact code, then add ---
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final code =
        capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (code == null || code.isEmpty) return;

    setState(() => _busy = true);
    try {
      final product = await ref.read(scanRepositoryProvider).resolve(code);
      if (!mounted) return;
      if (product == null) {
        await _alert('No hay ningún producto con el código:\n$code',
            AlertKind.warning);
        return;
      }
      await _addProduct(product);
    } catch (e) {
      if (mounted) await _alert('Error: $e', AlertKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Shared: add a product to the cart — or, if it's already there (e.g. the
  /// same size scanned twice), edit that line instead of duplicating it.
  Future<void> _addProduct(Product product) async {
    if (product.currentStock <= 0) {
      await _alert(
        '${product.name}\nSin stock — este producto ya se vendió.',
        AlertKind.warning,
      );
      return;
    }
    final notifier = ref.read(cartProvider.notifier);
    final index = notifier.indexOf(product.id);
    final existing = index != -1 ? ref.read(cartProvider)[index] : null;

    final input = await showModalBottomSheet<CartInput>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddToCartSheet(
        product: product,
        maxQuantity: product.currentStock,
        initialQuantity: existing?.quantity ?? 1,
        initialPrice: existing?.unitPrice,
        alreadyInCart: existing != null,
      ),
    );
    if (input == null) return;

    if (index != -1) {
      notifier.updateAt(index, input.quantity, input.unitPrice);
    } else {
      notifier.add(product, input.quantity, input.unitPrice);
    }
  }

  Future<void> _checkout() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;
    final items = <SaleLine>[
      for (final l in cart)
        (productId: l.product.id, quantity: l.quantity, unitPrice: l.unitPrice),
    ];
    // Which lines leave the product at/below its threshold after this sale?
    // Computed from cart data we already have — no extra server round-trip.
    final nowLow = <String>[
      for (final l in cart)
        if (l.product.currentStock - l.quantity <= l.product.lowStockThreshold)
          l.product.name,
    ];
    try {
      await ref.read(saleRepositoryProvider).registerSale(items);
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(productsProvider);
      ref.invalidate(salesReportProvider);
      ref.invalidate(lowStockProvider);
      final note = nowLow.isEmpty
          ? ''
          : '\n\n⚠️ Quedó poco stock de: ${nowLow.toSet().join(', ')}.';
      await _alert('La venta se registró correctamente.$note',
          AlertKind.success,
          title: 'Venta realizada');
      if (mounted) context.go('/sales');
    } on SaleException catch (e) {
      await _alert(e.message, AlertKind.error);
    }
  }

  Future<void> _alert(String message, AlertKind kind, {String? title}) async {
    if (!mounted) return;
    await showAppAlert(context, message: message, kind: kind, title: title);
  }

  Widget _scanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _cameraUnavailable(),
          ),
          if (_busy)
            const ColoredBox(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _cameraUnavailable() {
    return ColoredBox(
      color: AppColors.canvas,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_photography_outlined,
                size: 40, color: AppColors.inputBorder),
            const SizedBox(height: 12),
            const Text('Cámara no disponible',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Buscá el producto por nombre o código arriba.',
              style:
                  TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchField(List<Product> products) {
    return Autocomplete<Product>(
      displayStringForOption: (p) =>
          '${p.name}${p.detail != null ? ' · ${p.detail}' : ''}  (${p.sku})',
      optionsBuilder: (value) {
        final q = value.text.trim().toLowerCase();
        if (q.isEmpty) return const Iterable<Product>.empty();
        return products.where((p) {
          return p.name.toLowerCase().contains(q) ||
              p.sku.toLowerCase().contains(q) ||
              (p.detail?.toLowerCase().contains(q) ?? false);
        }).take(15);
      },
      onSelected: (product) async {
        await _addProduct(product);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Buscar por nombre o código',
            prefixIcon: Icon(Icons.search),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 460),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final p = options.elementAt(i);
                  return ListTile(
                    title: Text(
                        '${p.name}${p.detail != null ? ' · ${p.detail}' : ''}'),
                    subtitle: Text('${p.sku}  ·  stock ${p.currentStock}'),
                    onTap: () => onSelected(p),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider).asData?.value ?? const [];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Punto de venta',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text(
            'Escaneá o buscá productos, ajustá el precio y realizá la venta.',
            style: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                if (c.maxWidth >= 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _searchField(products),
                            const SizedBox(height: 12),
                            Expanded(child: _scanner()),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 380,
                        child: CartPanel(onCheckout: _checkout),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    _searchField(products),
                    const SizedBox(height: 12),
                    SizedBox(height: 240, child: _scanner()),
                    const SizedBox(height: 12),
                    Expanded(child: CartPanel(onCheckout: _checkout)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
