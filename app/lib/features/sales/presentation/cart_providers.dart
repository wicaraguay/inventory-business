import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/products/domain/product.dart';

/// One line in the current sale.
///
/// When [product] is null the line is a "quick sale" entry (no inventory item).
class CartLine {
  const CartLine({
    this.product,
    required this.quantity,
    required this.unitPrice,
    this.description,
    this.sizeLabel,
    this.date,
    this.explicitTotal,
  });

  final Product? product;       // null => venta rápida
  final int quantity;
  final double unitPrice;
  final String? description;    // obligatorio para ventas rápidas
  final String? sizeLabel;      // N° de par / talla (opcional)
  final DateTime? date;         // back-dating; null => hoy
  final double? explicitTotal;  // total exacto ingresado (venta rápida)

  bool get isQuick => product == null;

  double get subtotal => explicitTotal ?? quantity * unitPrice;
}

class CartNotifier extends Notifier<List<CartLine>> {
  @override
  List<CartLine> build() => const [];

  /// Add a product (inventory) line to the cart.
  void add(Product product, int quantity, double unitPrice) {
    state = [
      ...state,
      CartLine(product: product, quantity: quantity, unitPrice: unitPrice),
    ];
  }

  /// Add a quick-sale line (no product). [total] is the exact amount the owner
  /// charged for the whole line; unitPrice is derived as total / quantity.
  void addQuick({
    required int quantity,
    required double total,
    required String description,
    String? sizeLabel,
    DateTime? date,
  }) {
    final unitPrice = quantity > 0 ? total / quantity : total;
    state = [
      ...state,
      CartLine(
        product: null,
        quantity: quantity,
        unitPrice: unitPrice,
        description: description,
        sizeLabel: sizeLabel,
        date: date,
        explicitTotal: total,
      ),
    ];
  }

  void removeAt(int index) {
    final list = [...state]..removeAt(index);
    state = list;
  }

  /// Replace the quantity and unit price of an existing product line.
  void updateAt(int index, int quantity, double unitPrice) {
    final list = [...state];
    final line = list[index];
    list[index] = CartLine(
      product: line.product,
      quantity: quantity,
      unitPrice: unitPrice,
      description: line.description,
      sizeLabel: line.sizeLabel,
      date: line.date,
      explicitTotal: line.explicitTotal,
    );
    state = list;
  }

  /// Replace a quick-sale line at [index] with new values.
  void updateQuickAt(
    int index, {
    required int quantity,
    required double total,
    required String description,
    String? sizeLabel,
    DateTime? date,
  }) {
    final list = [...state];
    final unitPrice = quantity > 0 ? total / quantity : total;
    list[index] = CartLine(
      product: null,
      quantity: quantity,
      unitPrice: unitPrice,
      description: description,
      sizeLabel: sizeLabel,
      date: date,
      explicitTotal: total,
    );
    state = list;
  }

  void clear() => state = const [];

  /// Index of the (single) line for a product, or -1 if it isn't in the cart.
  /// Quick-sale lines (no product) are ignored safely.
  int indexOf(String productId) =>
      state.indexWhere((l) => !l.isQuick && l.product!.id == productId);

  /// How many units of a product are already in the cart.
  /// Quick-sale lines (no product) are ignored safely.
  int quantityFor(String productId) => state
      .where((l) => !l.isQuick && l.product!.id == productId)
      .fold(0, (sum, l) => sum + l.quantity);

  double get total => state.fold(0, (sum, l) => sum + l.subtotal);
}

final cartProvider =
    NotifierProvider<CartNotifier, List<CartLine>>(CartNotifier.new);
