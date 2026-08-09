import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventy_app/features/auth/domain/auth_user.dart';
import 'package:inventy_app/features/auth/presentation/auth_providers.dart';
import 'package:inventy_app/features/products/domain/bulk_product_input.dart';
import 'package:inventy_app/features/products/domain/product.dart';
import 'package:inventy_app/features/products/domain/product_repository.dart';
import 'package:inventy_app/features/products/presentation/products_providers.dart';
import 'package:inventy_app/features/products/presentation/products_screen.dart';
import 'package:inventy_app/features/settings/presentation/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fake repo: the container test needs no backend, no HTTP. Stateful so delete
/// actually removes the product (mirrors the real backend).
class _FakeProductRepository implements ProductRepository {
  final _items = <Product>[
    const Product(
      id: 'p1',
      name: 'Botín de cuero',
      sku: 'BOT-40',
      detail: 'talle 40 · negro',
      currentStock: 5,
      lowStockThreshold: 2,
    ),
    const Product(id: 'p2', name: 'Zapatilla', sku: 'ZAP-42', currentStock: 0),
  ];

  @override
  Future<Product> create({
    required String name,
    required String sku,
    required int lowStockThreshold,
    String? detail,
    double? salePrice,
    double? minPrice,
    double? supplierPrice,
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
    double? supplierPrice,
  }) async {}

  @override
  Future<List<Product>> createBulk(List<BulkProductInput> items) async => [
        for (final i in items)
          Product(id: i.sku, name: i.name, sku: i.sku, detail: i.detail),
      ];

  @override
  Future<List<Product>> addModelSizes(
    String modelId,
    List<BulkProductInput> items,
  ) async =>
      [
        for (final i in items)
          Product(id: i.sku, name: i.name, sku: i.sku, detail: i.detail),
      ];

  @override
  Future<void> delete(String id) async => _items.removeWhere((p) => p.id == id);

  @override
  Future<void> uploadImage(String id, Uint8List bytes) async {}

  @override
  Future<void> deleteImage(String id) async {}

  @override
  Future<List<Product>> list() async => List.of(_items);
}

const _owner = AuthUser(
  id: 'o1',
  username: 'nina',
  role: 'owner',
  displayName: 'Nina',
);

Future<void> _pumpScreen(WidgetTester tester, ProductRepository repo) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        productRepositoryProvider.overrideWithValue(repo),
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUserProvider.overrideWithValue(_owner),
      ],
      child: const MaterialApp(home: Scaffold(body: ProductsScreen())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ProductsScreen muestra la lista provista por el repo', (
    tester,
  ) async {
    await _pumpScreen(tester, _FakeProductRepository());
    expect(find.text('Botín de cuero'), findsOneWidget);
    expect(find.text('Zapatilla'), findsOneWidget);
  });

  testWidgets('borrar un producto lo saca de la lista sin crashear', (
    tester,
  ) async {
    await _pumpScreen(tester, _FakeProductRepository());
    expect(find.text('Botín de cuero'), findsOneWidget);

    // Open the first row's actions menu.
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();

    // Choose "Eliminar" in the menu.
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    // Confirm in the dialog.
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    // The product is gone and nothing crashed.
    expect(find.text('Botín de cuero'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
