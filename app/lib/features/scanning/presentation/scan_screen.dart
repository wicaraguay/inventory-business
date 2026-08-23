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
import 'package:inventy_app/features/sales/presentation/widgets/quick_sale_sheet.dart';
import 'package:inventy_app/features/scanning/presentation/scanning_providers.dart';
import 'package:inventy_app/features/settings/presentation/settings_providers.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';
import 'package:inventy_app/shared/ui/app_alert.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Which input mode is active on the sales screen.
enum _SaleMode { quick, qr }

/// Point of sale: quick-sale form (default) or QR scanner — both feed the same
/// cart. A single "Realizar venta" button covers all lines.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  // QR scanner controller — lazy: only used when _mode == qr.
  MobileScannerController? _controller;

  // UI mode: quick-sale form or QR camera. This is pure UI state.
  _SaleMode _mode = _SaleMode.quick;

  // Whether the scanner is resolving a code (prevents double-scan).
  bool _busy = false;

  void _setMode(_SaleMode mode) {
    if (_mode == mode) return;
    if (mode == _SaleMode.qr) {
      _controller ??= MobileScannerController(
        formats: const [BarcodeFormat.qrCode],
      );
    } else {
      // Stop the camera when switching away — saves battery/resources.
      _controller?.stop();
    }
    setState(() => _mode = mode);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // --- Scanner path ---
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

  /// Add an inventory product to the cart — or edit the existing line.
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
      showDragHandle: true,
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

  /// Show the quick-sale sheet modally and add the result to the cart.
  Future<void> _addQuick() async {
    final input = await showModalBottomSheet<QuickSaleInput>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const QuickSaleSheet(),
    );
    if (input == null) return;
    ref.read(cartProvider.notifier).addQuick(
          quantity: input.quantity,
          total: input.total,
          description: input.description,
          sizeLabel: input.sizeLabel,
          date: input.date,
        );
  }

  Future<void> _checkout() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    final items = <SaleLine>[
      for (final l in cart)
        (
          productId: l.isQuick ? null : l.product!.id,
          quantity: l.quantity,
          unitPrice: l.unitPrice,
          total: l.explicitTotal,
          description: l.description,
          sizeLabel: l.sizeLabel,
          createdAt: l.date,
        ),
    ];

    // Low-stock check (only inventory lines can deplete stock).
    final threshold = ref.read(settingsProvider).defaultThreshold;
    final nowLow = <String>[
      for (final l in cart)
        if (!l.isQuick &&
            l.product!.currentStock - l.quantity <= threshold)
          l.product!.name,
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

  // --- Scanner widget ---
  Widget _scanner() {
    final ctrl = _controller!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: ctrl,
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
              'Buscá el producto por nombre o código.',
              style: TextStyle(
                  color: AppColors.onSurface.withValues(alpha: 0.6)),
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
              constraints:
                  const BoxConstraints(maxHeight: 280, maxWidth: 460),
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

  // --- Mode toggle bar ---
  Widget _modeToggle() {
    return SegmentedButton<_SaleMode>(
      segments: const [
        ButtonSegment(
          value: _SaleMode.quick,
          icon: Icon(Icons.shopping_bag_outlined),
          label: Text('Venta rápida'),
        ),
        ButtonSegment(
          value: _SaleMode.qr,
          icon: Icon(Icons.qr_code_scanner),
          label: Text('Escanear QR'),
        ),
      ],
      selected: {_mode},
      onSelectionChanged: (s) => _setMode(s.first),
    );
  }

  // --- Quick-sale mode content ---
  Widget _quickSaleContent(List<Product> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search (inventory) field stays available in quick mode too.
        _searchField(products),
        const SizedBox(height: 12),
        // Big prominent button to open the quick-sale form.
        FilledButton.tonalIcon(
          onPressed: _addQuick,
          icon: const Icon(Icons.add),
          label: const Text('Agregar venta rápida'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Usá el buscador para agregar productos del inventario, '
          'o el botón de arriba para registrar una venta sin producto.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.onSurface.withValues(alpha: 0.55),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // --- QR-scan mode content ---
  Widget _qrContent(List<Product> products) {
    return Column(
      children: [
        _searchField(products),
        const SizedBox(height: 12),
        Expanded(child: _scanner()),
      ],
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
            'Registrá ventas rápidas o escaneá QR del inventario.',
            style: TextStyle(
                color: AppColors.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 12),
          _modeToggle(),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final leftPanel = _mode == _SaleMode.quick
                    ? _quickSaleContent(products)
                    : _qrContent(products);

                if (c.maxWidth >= 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: leftPanel),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 380,
                        child: CartPanel(onCheckout: _checkout),
                      ),
                    ],
                  );
                }
                // Narrow layout: left panel takes its natural height (quick mode)
                // or a fixed 240 height (QR mode), then cart fills the rest.
                return Column(
                  children: [
                    if (_mode == _SaleMode.qr)
                      SizedBox(height: 240, child: leftPanel)
                    else
                      leftPanel,
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
