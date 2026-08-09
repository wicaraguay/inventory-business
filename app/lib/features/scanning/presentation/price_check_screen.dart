import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/products/domain/product.dart';
import 'package:inventy_app/features/scanning/presentation/scanning_providers.dart';
import 'package:inventy_app/features/settings/presentation/settings_providers.dart';
import 'package:inventy_app/shared/format.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';
import 'package:inventy_app/shared/ui/product_image.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Fast price check for the counter: scan a shelf QR and see the price, that
/// size, its stock, the model's other sizes with stock, and the photo. The
/// camera is a bounded box (like the register) with the info below it.
class PriceCheckScreen extends ConsumerStatefulWidget {
  const PriceCheckScreen({super.key});

  @override
  ConsumerState<PriceCheckScreen> createState() => _PriceCheckScreenState();
}

class _PriceCheckScreenState extends ConsumerState<PriceCheckScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  bool _busy = false;
  String? _lastCode;
  Product? _found;
  String? _notFoundCode;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final code =
        capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (code == null || code.isEmpty || code == _lastCode) return;

    setState(() {
      _busy = true;
      _lastCode = code;
    });
    try {
      final product = await ref.read(scanRepositoryProvider).resolve(code);
      if (!mounted) return;
      setState(() {
        _found = product;
        _notFoundCode = product == null ? code : null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _found = null;
          _notFoundCode = code;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6));
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Consultar precio',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text('Escaneá el QR del zapato para ver precio, stock y tallas.',
              style: muted),
          const SizedBox(height: 12),
          // Camera sized like the register (bounded box), not full screen.
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 260,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                    errorBuilder: (context, error) => _cameraUnavailable(),
                  ),
                  const Center(
                    child: Icon(Icons.qr_code_scanner,
                        size: 90, color: Colors.white24),
                  ),
                  if (_busy)
                    const ColoredBox(
                      color: Colors.black26,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: SingleChildScrollView(child: _result())),
        ],
      ),
    );
  }

  Widget _result() {
    if (_found == null && _notFoundCode == null) {
      return Text(
        'Apuntá al QR para ver el precio.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6)),
      );
    }
    if (_notFoundCode != null) {
      return Card(
        color: AppColors.danger.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.danger),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Sin producto para el código:\n$_notFoundCode'),
              ),
            ],
          ),
        ),
      );
    }
    final p = _found!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.hasImage) ...[
                  ProductThumbnail(product: p, size: 96),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      if (p.detail != null && p.detail!.isNotEmpty)
                        Text(
                          p.detail!,
                          style: TextStyle(
                              fontSize: 15,
                              color: AppColors.onSurface.withValues(alpha: 0.7)),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        p.salePrice == null
                            ? 'Sin precio cargado'
                            : money(p.salePrice),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          color: p.salePrice == null
                              ? AppColors.onSurface.withValues(alpha: 0.5)
                              : AppColors.primary,
                        ),
                      ),
                      if (p.minPrice != null)
                        Text('Mínimo ${money(p.minPrice)}',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color:
                                    AppColors.onSurface.withValues(alpha: 0.7))),
                      const SizedBox(height: 8),
                      _stockChip(p),
                    ],
                  ),
                ),
              ],
            ),
            if (p.availableSizes.length > 1) ...[
              const Divider(height: 24),
              Text('Tallas del modelo',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final s in p.availableSizes) _sizeChip(s)],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stockChip(Product p) {
    final threshold = ref.read(settingsProvider).defaultThreshold;
    final (color, label) = switch (p) {
      _ when p.currentStock <= 0 => (AppColors.danger, 'Sin stock'),
      _ when p.currentStock <= threshold =>
        (AppColors.warning, 'Quedan ${p.currentStock} (bajo)'),
      _ => (AppColors.success, 'Stock ${p.currentStock}'),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      ),
    );
  }

  /// A chip for one size: label + stock. Muted/struck when out of stock.
  Widget _sizeChip(ModelSize s) {
    final out = s.currentStock <= 0;
    final color =
        out ? AppColors.onSurface.withValues(alpha: 0.4) : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${s.label} · ${s.currentStock}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          decoration: out ? TextDecoration.lineThrough : null,
        ),
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
          ],
        ),
      ),
    );
  }
}
