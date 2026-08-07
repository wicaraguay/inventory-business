import 'package:inventy_backend/src/domain/entities/sale_item.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';
import 'package:inventy_backend/src/domain/ports/sales_repository.dart';
import 'package:inventy_backend/src/domain/ports/stock_repository.dart';

/// Use case: register a sale of one or more items at chosen prices.
/// Decrements stock. Rule: cannot sell more than what is in stock.
class RegisterSale {
  RegisterSale(this._sales, this._stock);

  final SalesRepository _sales;
  final StockRepository _stock;

  Future<void> call(List<SaleItem> items) async {
    if (items.isEmpty) {
      throw DomainException('La venta no tiene productos');
    }
    for (final item in items) {
      if (item.productId.trim().isEmpty) {
        throw DomainException('El producto es obligatorio');
      }
      if (item.quantity <= 0) {
        throw DomainException('La cantidad debe ser positiva');
      }
      if (item.unitPrice < 0) {
        throw DomainException('El precio no puede ser negativo');
      }
    }

    // Aggregate quantity per product (same product may appear twice).
    final byProduct = <String, int>{};
    for (final item in items) {
      byProduct[item.productId] =
          (byProduct[item.productId] ?? 0) + item.quantity;
    }
    for (final entry in byProduct.entries) {
      final available = await _stock.currentStock(entry.key);
      if (entry.value > available) {
        throw DomainException(
          'Stock insuficiente: hay $available disponible(s)',
        );
      }
    }

    await _sales.register(items);
  }
}
