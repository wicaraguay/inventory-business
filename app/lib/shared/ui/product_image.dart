import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/products/domain/product.dart';
import 'package:inventy_app/shared/api/api_client.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';

/// Full URL of a product's image. Versioned (?v=) so the browser refetches it
/// whenever the image changes.
String productImageUrl(String baseUrl, Product product) =>
    '$baseUrl/products/${product.id}/image?v=${product.imageVersion}';

/// A small rounded product image. Shows a neutral placeholder when the product
/// has no image. When it does (and [enlargeOnTap]), tapping opens it large.
class ProductThumbnail extends ConsumerWidget {
  const ProductThumbnail({
    required this.product,
    this.size = 44,
    this.enlargeOnTap = true,
    super.key,
  });

  final Product product;
  final double size;
  final bool enlargeOnTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = BorderRadius.circular(size < 56 ? 8 : 12);

    if (!product.hasImage) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: radius,
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Icon(
          Icons.image_outlined,
          size: size * 0.5,
          color: AppColors.inputBorder,
        ),
      );
    }

    final url = productImageUrl(ref.watch(apiBaseUrlProvider), product);
    final image = ClipRRect(
      borderRadius: radius,
      child: Image.network(
        url,
        headers: apiAuthHeaders,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: AppColors.canvas,
          child: const Icon(Icons.broken_image_outlined,
              color: AppColors.inputBorder),
        ),
      ),
    );

    if (!enlargeOnTap) return image;
    return GestureDetector(
      onTap: () => showProductImageDialog(context, url, product.name),
      child: MouseRegion(cursor: SystemMouseCursors.click, child: image),
    );
  }
}

/// Shows the product image large. Tap the backdrop or the ✕ to close it and
/// return to the small thumbnail. Pinch/scroll to zoom.
Future<void> showProductImageDialog(
  BuildContext context,
  String url,
  String name,
) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(ctx).pop(),
            child: InteractiveViewer(
              maxScale: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(url,
                    headers: apiAuthHeaders, fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
