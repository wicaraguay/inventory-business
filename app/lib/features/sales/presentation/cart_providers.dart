import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/products/domain/product.dart';

/// One line in the current sale.
class CartLine {
  const CartLine({
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });

  final Product product;
  final int quantity;
  final double unitPrice;

  double get subtotal => quantity * unitPrice;
}

class CartNotifier extends Notifier<List<CartLine>> {
  @override
  List<CartLine> build() => const [];

  void add(Product product, int quantity, double unitPrice) {
    state = [
      ...state,
      CartLine(product: product, quantity: quantity, unitPrice: unitPrice),
    ];
  }

  void removeAt(int index) {
    final list = [...state]..removeAt(index);
    state = list;
  }

  /// Replace the quantity and unit price of an existing line.
  void updateAt(int index, int quantity, double unitPrice) {
    final list = [...state];
    final line = list[index];
    list[index] = CartLine(
      product: line.product,
      quantity: quantity,
      unitPrice: unitPrice,
    );
    state = list;
  }

  void clear() => state = const [];

  /// Index of the (single) line for a product, or -1 if it isn't in the cart.
  int indexOf(String productId) =>
      state.indexWhere((l) => l.product.id == productId);

  /// How many units of a product are already in the cart.
  int quantityFor(String productId) => state
      .where((l) => l.product.id == productId)
      .fold(0, (sum, l) => sum + l.quantity);

  double get total => state.fold(0, (sum, l) => sum + l.subtotal);
}

final cartProvider =
    NotifierProvider<CartNotifier, List<CartLine>>(CartNotifier.new);
