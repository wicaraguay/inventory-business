import 'package:inventy_backend/src/domain/entities/sale_item.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';
import 'package:inventy_backend/src/domain/ports/sales_repository.dart';
import 'package:inventy_backend/src/domain/ports/stock_repository.dart';

/// Use case: register a sale of one or more items at chosen prices.
/// - Items WITH productId: validate and decrement stock.
/// - Items WITHOUT productId (quick sales): require description; no stock check.
class RegisterSale {
  RegisterSale(this._sales, this._stock);

  final SalesRepository _sales;
  final StockRepository _stock;

  Future<void> call(List<SaleItem> items) async {
    if (items.isEmpty) {
      throw DomainException('La venta no tiene productos');
    }

    for (final item in items) {
      if (item.quantity <= 0) {
        throw DomainException('La cantidad debe ser positiva');
      }
      if (item.unitPrice < 0) {
        throw DomainException('El precio no puede ser negativo');
      }

      if (item.isQuickSale) {
        // Quick sale: description is mandatory.
        if (item.description == null || item.description!.trim().isEmpty) {
          throw DomainException('La descripción es obligatoria');
        }
      }
    }

    // Aggregate quantity per product for stock check (only inventory items).
    final byProduct = <String, int>{};
    for (final item in items) {
      if (!item.isQuickSale) {
        final pid = item.productId!;
        byProduct[pid] = (byProduct[pid] ?? 0) + item.quantity;
      }
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
