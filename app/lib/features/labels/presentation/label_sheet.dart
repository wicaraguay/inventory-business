import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:inventy_app/features/labels/data/label_printer.dart';
import 'package:inventy_app/features/products/domain/product.dart';
import 'package:inventy_app/shared/ui/app_alert.dart';

/// Preview of a product's QR label + a print button. The QR encodes the SKU,
/// which the scanner resolves back to the product.
class LabelSheet extends StatelessWidget {
  const LabelSheet({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Etiqueta QR', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Center(
            child: BarcodeWidget(
              barcode: Barcode.qrCode(),
              data: product.sku,
              width: 180,
              height: 180,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (product.detail != null) Text(product.detail!),
                Text(product.sku),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            // Same fixed 12-column QR format as bulk. Prints one QR per pair in
            // stock; warns when the size is at 0 (nothing to label yet).
            onPressed: () async {
              final printed = await printProductLabels([product]);
              if (printed == 0 && context.mounted) {
                await showAppAlert(context,
                    message: 'Esta talla está en 0 — no hay pares para '
                        'etiquetar. Cargá stock y volvé a imprimir.',
                    kind: AlertKind.info);
              }
            },
            icon: const Icon(Icons.print),
            label: const Text('Imprimir'),
          ),
        ],
      ),
    );
  }
}
