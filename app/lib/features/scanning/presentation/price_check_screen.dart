import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/products/domain/product.dart';
import 'package:inventy_app/features/scanning/presentation/scanning_providers.dart';
import 'package:inventy_app/features/settings/presentation/settings_providers.dart';
import 'package:inventy_app/shared/format.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';
import 'package:inventy_app/shared/ui/product_image.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Fast price check for the counter: scan a shelf QR and instantly see the
/// price (and the minimum, for haggling) + the photo. Read-only, no stock —
/// built so an employee can quote a walk-in customer in one second.
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
    return Stack(
      children: [
        Positioned.fill(
          child: MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _cameraUnavailable(),
          ),
        ),
        const Center(
          child: Icon(Icons.qr_code_scanner, size: 120, color: Colors.white24),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _result(),
          ),
        ),
      ],
    );
  }

  Widget _result() {
    if (_found == null && _notFoundCode == null) {
      return _card(
        color: Colors.black.withValues(alpha: 0.6),
        child: const Text(
          'Escaneá el QR del producto para ver su precio.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    if (_notFoundCode != null) {
      return _card(
        color: AppColors.danger,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              'Sin producto para el código:\n$_notFoundCode',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }
    final p = _found!;
    return _card(
      color: AppColors.surface,
      child: Row(
        children: [
          if (p.hasImage) ...[
            ProductThumbnail(product: p, size: 88),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (p.detail != null && p.detail!.isNotEmpty)
                  Text(
                    p.detail!,
                    style: TextStyle(
                        color: AppColors.onSurface.withValues(alpha: 0.6)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Text(
                  p.salePrice == null ? 'Sin precio cargado' : money(p.salePrice),
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: p.salePrice == null
                        ? AppColors.onSurface.withValues(alpha: 0.5)
                        : AppColors.primary,
                    height: 1.1,
                  ),
                ),
                if (p.minPrice != null)
                  Text(
                    'Mínimo ${money(p.minPrice)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                const SizedBox(height: 8),
                _stockChip(p),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Small colored badge telling the employee if there's stock to sell.
  Widget _stockChip(Product p) {
    final threshold = ref.read(settingsProvider).defaultThreshold;
    final (color, label) = switch (p) {
      _ when p.currentStock <= 0 => (AppColors.danger, 'Sin stock'),
      _ when p.currentStock <= threshold =>
        (AppColors.warning, 'Quedan ${p.currentStock} (bajo)'),
      _ => (AppColors.success, 'Stock ${p.currentStock}'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _card({required Color color, required Widget child}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Card(
        color: color,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
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
