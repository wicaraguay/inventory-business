import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventy_app/features/products/domain/bulk_product_input.dart';
import 'package:inventy_app/features/products/domain/product.dart';
import 'package:inventy_app/features/products/domain/product_repository.dart';
import 'package:inventy_app/features/products/presentation/products_providers.dart';
import 'package:inventy_app/features/products/presentation/products_screen.dart';

/// Fake repo: the container test needs no backend, no HTTP.
class _FakeProductRepository implements ProductRepository {
  @override
  Future<Product> create({
    required String name,
    required String sku,
    required int lowStockThreshold,
    String? detail,
    double? salePrice,
    double? minPrice,
  }) async =>
      Product(id: 'x', name: name, sku: sku);

  @override
  Future<void> update({
    required String id,
    required String name,
    required String sku,
    required int lowStockThreshold,
    String? detail,
    double? salePrice,
    double? minPrice,
  }) async {}

  @override
  Future<List<Product>> createBulk(List<BulkProductInput> items) async => [
        for (final i in items)
          Product(id: i.sku, name: i.name, sku: i.sku, detail: i.detail),
      ];

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> uploadImage(String id, Uint8List bytes) async {}

  @override
  Future<void> deleteImage(String id) async {}

  @override
  Future<List<Product>> list() async => const [
        Product(
          id: 'p1',
          name: 'Botín de cuero',
          sku: 'BOT-40',
          detail: 'talle 40 · negro',
          currentStock: 5,
          lowStockThreshold: 2,
        ),
        Product(id: 'p2', name: 'Zapatilla', sku: 'ZAP-42', currentStock: 0),
      ];
}

void main() {
  testWidgets('ProductsScreen muestra la lista provista por el repo', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(_FakeProductRepository()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ProductsScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Botín de cuero'), findsOneWidget);
    expect(find.text('Zapatilla'), findsOneWidget);
  });
}
