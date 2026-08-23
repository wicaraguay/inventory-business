import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventy_app/features/products/domain/product.dart';
import 'package:inventy_app/features/sales/presentation/cart_providers.dart';
import 'package:inventy_app/features/sales/presentation/widgets/quick_sale_sheet.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// A product used in inventory-line tests.
const _product = Product(
  id: 'p1',
  name: 'Botín de cuero',
  sku: 'BOT-40',
  currentStock: 10,
);

/// Build a minimal ProviderScope with a fresh cart.
ProviderContainer _container() => ProviderContainer();

// ---------------------------------------------------------------------------
// CartNotifier unit tests
// ---------------------------------------------------------------------------

void main() {
  group('CartNotifier — addQuick', () {
    test('agrega una línea rápida y el subtotal es el total exacto', () {
      final container = _container();
      addTearDown(container.dispose);
      final notifier = container.read(cartProvider.notifier);

      notifier.addQuick(
        quantity: 2,
        total: 50,
        description: 'Botín de cuero',
      );

      final cart = container.read(cartProvider);
      expect(cart.length, 1);
      final line = cart.first;
      expect(line.isQuick, isTrue);
      expect(line.subtotal, 50.0);
      expect(line.quantity, 2);
      expect(line.unitPrice, 25.0); // 50 / 2
      expect(line.description, 'Botín de cuero');
    });

    test('total del carrito suma líneas rápidas + inventario', () {
      final container = _container();
      addTearDown(container.dispose);
      final notifier = container.read(cartProvider.notifier);

      // Línea de inventario: 3 unidades × $20 = $60.
      notifier.add(_product, 3, 20);
      // Línea rápida: total exacto $45.
      notifier.addQuick(
        quantity: 1,
        total: 45,
        description: 'Zapatilla sin stock',
      );

      expect(notifier.total, 105.0); // 60 + 45
    });

    test('addQuick con quantity=1 => unitPrice == total', () {
      final container = _container();
      addTearDown(container.dispose);
      final notifier = container.read(cartProvider.notifier);

      notifier.addQuick(
        quantity: 1,
        total: 37.5,
        description: 'Par suelto',
        sizeLabel: '38',
      );

      final line = container.read(cartProvider).first;
      expect(line.unitPrice, 37.5);
      expect(line.sizeLabel, '38');
      expect(line.explicitTotal, 37.5);
    });

    test('addQuick conserva la fecha si se pasa', () {
      final container = _container();
      addTearDown(container.dispose);
      final notifier = container.read(cartProvider.notifier);

      final yesterday = DateTime(2026, 8, 22);
      notifier.addQuick(
        quantity: 1,
        total: 20,
        description: 'Venta de ayer',
        date: yesterday,
      );

      final line = container.read(cartProvider).first;
      expect(line.date, yesterday);
    });

    test('varias líneas rápidas + inventario: total correcto', () {
      final container = _container();
      addTearDown(container.dispose);
      final notifier = container.read(cartProvider.notifier);

      notifier.addQuick(quantity: 2, total: 80, description: 'Línea A');
      notifier.addQuick(quantity: 3, total: 90, description: 'Línea B');
      notifier.add(_product, 1, 30);

      expect(notifier.total, 200.0); // 80 + 90 + 30
    });
  });

  group('CartNotifier — indexOf / quantityFor con líneas quick', () {
    test('indexOf no crashea con líneas rápidas presentes y devuelve -1 '
        'para un producto no agregado', () {
      final container = _container();
      addTearDown(container.dispose);
      final notifier = container.read(cartProvider.notifier);

      notifier.addQuick(quantity: 1, total: 10, description: 'Rápida');

      // No debe lanzar null-check; debe devolver -1.
      expect(notifier.indexOf('product-inexistente'), -1);
    });

    test('indexOf encuentra la línea de inventario correcta '
        'cuando hay líneas rápidas intercaladas', () {
      final container = _container();
      addTearDown(container.dispose);
      final notifier = container.read(cartProvider.notifier);

      notifier.addQuick(quantity: 1, total: 10, description: 'Rápida primero');
      notifier.add(_product, 2, 15); // index 1

      expect(notifier.indexOf(_product.id), 1);
    });

    test('quantityFor no crashea con líneas rápidas presentes', () {
      final container = _container();
      addTearDown(container.dispose);
      final notifier = container.read(cartProvider.notifier);

      notifier.addQuick(quantity: 1, total: 10, description: 'Rápida');
      notifier.add(_product, 3, 15);

      expect(notifier.quantityFor(_product.id), 3);
      expect(notifier.quantityFor('otro-producto'), 0);
    });
  });

  // -------------------------------------------------------------------------
  // Widget test: QuickSaleSheet
  // -------------------------------------------------------------------------

  // -------------------------------------------------------------------------
  // Widget test: QuickSaleSheet rendered directly (not as a modal, avoids
  // overlay/viewport issues in the test environment).
  // -------------------------------------------------------------------------

  group('QuickSaleSheet widget', () {
    /// Pump the sheet directly inside a Scaffold — no modal overlay needed.
    Future<void> pumpDirect(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: QuickSaleSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('descripción vacía no permite confirmar', (tester) async {
      await pumpDirect(tester);

      // Scroll to make the submit button visible and tap it.
      await tester.scrollUntilVisible(
        find.text('Agregar a la venta'),
        50,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.text('Agregar a la venta'));
      await tester.pumpAndSettle();

      expect(find.text('La descripción es obligatoria'), findsOneWidget);
    });

    testWidgets('con datos válidos cierra el formulario sin error de validación',
        (tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: const QuickSaleSheet(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fill description.
      final descField = find.widgetWithText(TextFormField, 'Descripción *');
      await tester.enterText(descField, 'Botín negro');
      await tester.pump();

      // Fill total.
      final totalField = find.widgetWithText(TextFormField, 'Total cobrado *');
      await tester.enterText(totalField, '60');
      await tester.pump();

      // Scroll to submit button and tap.
      await tester.scrollUntilVisible(
        find.text('Agregar a la venta'),
        50,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.text('Agregar a la venta'));
      await tester.pumpAndSettle();

      // Should NOT show any validation error.
      expect(find.text('La descripción es obligatoria'), findsNothing);
      expect(find.text('Total inválido'), findsNothing);
    });

    testWidgets('total negativo no permite confirmar', (tester) async {
      await pumpDirect(tester);

      final descField = find.widgetWithText(TextFormField, 'Descripción *');
      await tester.enterText(descField, 'Test');
      await tester.pump();

      final totalField = find.widgetWithText(TextFormField, 'Total cobrado *');
      await tester.enterText(totalField, '-5');
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Agregar a la venta'),
        50,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.text('Agregar a la venta'));
      await tester.pumpAndSettle();

      expect(find.text('Total inválido'), findsOneWidget);
    });
  });
}
