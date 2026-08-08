import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/products/data/http_product_repository.dart';
import 'package:inventy_app/features/products/domain/bulk_product_input.dart';
import 'package:inventy_app/features/dashboard/presentation/dashboard_providers.dart';
import 'package:inventy_app/features/movements/presentation/movements_providers.dart';
import 'package:inventy_app/features/products/domain/product.dart';
import 'package:inventy_app/features/products/domain/product_repository.dart';
import 'package:inventy_app/shared/api/api_client.dart';

/// Wires the HTTP implementation. Tests override THIS to inject a fake.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return HttpProductRepository(ref.watch(dioProvider));
});

/// Owns the products list state and its side effects (container brain).
class ProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() {
    return ref.watch(productRepositoryProvider).list();
  }

  Future<void> create({
    required String name,
    required String sku,
    required int lowStockThreshold,
    String? detail,
    double? salePrice,
    double? minPrice,
    int initialStock = 0,
    Uint8List? imageBytes,
  }) async {
    final repo = ref.read(productRepositoryProvider);
    final created = await repo.create(
      name: name,
      sku: sku,
      lowStockThreshold: lowStockThreshold,
      detail: detail,
      salePrice: salePrice,
      minPrice: minPrice,
    );
    // Stock is derived from movements: seed it with an initial entry.
    if (initialStock > 0) {
      await ref.read(movementRepositoryProvider).registerEntry(
            productId: created.id,
            quantity: initialStock,
            note: 'Carga inicial',
          );
    }
    if (imageBytes != null) {
      await repo.uploadImage(created.id, imageBytes);
    }
    ref.invalidateSelf();
    await future;
  }

  /// Creates all sizes of a model at once and returns the created products
  /// (with ids) so the caller can print their labels.
  Future<List<Product>> bulkCreate(List<BulkProductInput> items) async {
    final created =
        await ref.read(productRepositoryProvider).createBulk(items);
    ref.invalidateSelf();
    await future;
    return created;
  }

  Future<void> edit({
    required String id,
    required String name,
    required String sku,
    required int lowStockThreshold,
    String? detail,
    double? salePrice,
    double? minPrice,
    Uint8List? imageBytes,
    bool removeImage = false,
  }) async {
    final repo = ref.read(productRepositoryProvider);
    await repo.update(
      id: id,
      name: name,
      sku: sku,
      lowStockThreshold: lowStockThreshold,
      detail: detail,
      salePrice: salePrice,
      minPrice: minPrice,
    );
    if (imageBytes != null) {
      await repo.uploadImage(id, imageBytes);
    } else if (removeImage) {
      await repo.deleteImage(id);
    }
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(String id) async {
    debugPrint('🗑️ [notifier] repo.delete($id)...');
    await ref.read(productRepositoryProvider).delete(id);
    debugPrint('🗑️ [notifier] repo.delete OK, actualizando estado');
    // The product is gone on the server: drop it from the in-memory list rather
    // than refetching (a refetch that errors could blank the screen). Refresh
    // the low-stock alerts so the deleted product also leaves them.
    final current = state.asData?.value ?? const <Product>[];
    state = AsyncData([for (final p in current) if (p.id != id) p]);
    debugPrint('🗑️ [notifier] estado actualizado (quedan ${current.length - 1})');
    ref.invalidate(lowStockProvider);
    debugPrint('🗑️ [notifier] lowStock invalidado — fin delete');
  }
}

final productsProvider =
    AsyncNotifierProvider<ProductsNotifier, List<Product>>(
  ProductsNotifier.new,
);
