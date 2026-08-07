import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/products/domain/product.dart';
import 'package:inventy_app/features/scanning/presentation/scanning_providers.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';
import 'package:inventy_app/shared/ui/product_image.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Full-screen QR identifier for the labeling workflow: scan a printed QR and it
/// tells you which shoe/size it belongs to — then scan the next one. It never
/// changes stock; it only reads. Ideal after bulk-printing "QR-only" labels.
class IdentifyScreen extends ConsumerStatefulWidget {
  const IdentifyScreen({super.key});

  @override
  ConsumerState<IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends ConsumerState<IdentifyScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  bool _busy = false;
  String? _lastCode;
  Product? _found;
  String? _notFoundCode;

  @override
  void dispose() {
    // Release the camera (important on web, where tracks otherwise linger).
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final code =
        capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (code == null || code.isEmpty) return;
    // Ignore the SAME code repeating (the camera fires many times per second).
    if (code == _lastCode) return;

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
    return Scaffold(
      appBar: AppBar(title: const Text('Identificar QR')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _cameraUnavailable(),
          ),
          // Aiming hint.
          const Center(
            child: Icon(Icons.qr_code_scanner,
                size: 120, color: Colors.white24),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _result(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _result() {
    if (_found == null && _notFoundCode == null) {
      return _card(
        color: Colors.black.withValues(alpha: 0.6),
        child: const Text(
          'Apuntá al QR de una etiqueta para ver a qué zapato pertenece.',
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
    final low = p.currentStock <= p.lowStockThreshold;
    return _card(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Show the product photo if it has one (tap to enlarge).
          if (p.hasImage) ...[
            Center(child: ProductThumbnail(product: p, size: 96)),
            const SizedBox(height: 10),
          ],
          Text(
            p.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          if (p.detail != null && p.detail!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              p.detail!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, color: AppColors.onSurface.withValues(alpha: 0.7)),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                p.sku,
                style: TextStyle(
                    fontFamily: 'monospace',
                    color: AppColors.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (low ? AppColors.warning : AppColors.success)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Stock ${p.currentStock}',
                  style: TextStyle(
                    color: low ? AppColors.warning : AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Escaneá el siguiente QR',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: AppColors.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _card({required Color color, required Widget child}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
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
            const Icon(Icons.no_photography_outlined,
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
