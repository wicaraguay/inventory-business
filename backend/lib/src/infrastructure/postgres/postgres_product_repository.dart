import 'package:inventy_backend/src/domain/entities/bulk_product_input.dart';
import 'package:inventy_backend/src/domain/entities/model_size.dart';
import 'package:inventy_backend/src/domain/entities/product.dart';
import 'package:inventy_backend/src/domain/entities/product_with_stock.dart';
import 'package:inventy_backend/src/domain/ports/product_repository.dart';
import 'package:postgres/postgres.dart';

/// ADAPTER: products persistence on Postgres.
class PostgresProductRepository implements ProductRepository {
  PostgresProductRepository(this._db);

  final Connection _db;

  // Prices cast to float8 so the driver reads them as doubles (not numeric->String).
  static const _cols = 'p.id, p.name, p.detail, p.sku, p.low_stock_threshold, '
      'p.sale_price::float8, p.min_price::float8, '
      'p.supplier_price::float8, p.model_id';

  static const _returning = 'id, name, detail, sku, low_stock_threshold, '
      'sale_price::float8, min_price::float8, supplier_price::float8, model_id';

  @override
  Future<Product> create({
    required String name,
    required String sku,
    required int lowStockThreshold,
    String? detail,
    double? salePrice,
    double? minPrice,
    double? supplierPrice,
  }) async {
    final result = await _db.execute(
      Sql.named('''
        INSERT INTO products
          (name, detail, sku, low_stock_threshold, sale_price, min_price,
           supplier_price)
        VALUES (@name, @detail, @sku, @threshold, @salePrice, @minPrice,
           @supplierPrice)
        RETURNING $_returning
      '''),
      parameters: {
        'name': name,
        'detail': detail,
        'sku': sku,
        'threshold': lowStockThreshold,
        'salePrice': salePrice,
        'minPrice': minPrice,
        'supplierPrice': supplierPrice,
      },
    );
    return _map(result.first);
  }

  @override
  Future<List<Product>> createBulk(List<BulkProductInput> items) async {
    final created = <Product>[];
    await _db.runTx((tx) async {
      // The first size uses the default model_id; the rest share it, so all
      // sizes of this load belong to the same model.
      String? sharedModelId;
      for (final item in items) {
        final withModel = sharedModelId != null;
        final result = await tx.execute(
          Sql.named('''
            INSERT INTO products
              (name, detail, sku, low_stock_threshold, sale_price, min_price,
               supplier_price${withModel ? ', model_id' : ''})
            VALUES (@name, @detail, @sku, @threshold, @salePrice, @minPrice,
               @supplierPrice${withModel ? ', @modelId' : ''})
            RETURNING $_returning
          '''),
          parameters: {
            'name': item.name,
            'detail': item.detail,
            'sku': item.sku,
            'threshold': item.lowStockThreshold,
            'salePrice': item.salePrice,
            'minPrice': item.minPrice,
            'supplierPrice': item.supplierPrice,
            if (withModel) 'modelId': sharedModelId,
          },
        );
        final product = _map(result.first);
        sharedModelId ??= product.modelId;
        if (item.initialStock > 0) {
          await tx.execute(
            Sql.named('''
              INSERT INTO stock_movements (product_id, quantity, type, note)
              VALUES (@productId, @quantity, 'entry', 'Carga inicial')
            '''),
            parameters: {
              'productId': product.id,
              'quantity': item.initialStock,
            },
          );
        }
        created.add(product);
      }
    });
    return created;
  }

  @override
  Future<Product> update({
    required String id,
    required String name,
    required String sku,
    required int lowStockThreshold,
    String? detail,
    double? salePrice,
    double? minPrice,
    double? supplierPrice,
  }) async {
    final result = await _db.execute(
      Sql.named('''
        UPDATE products SET
          name = @name, detail = @detail, sku = @sku,
          low_stock_threshold = @threshold, sale_price = @salePrice,
          min_price = @minPrice,
          -- Keep the cost if the caller didn't send one (e.g. an employee's
          -- edit form, which never shows it). Only the owner changes it.
          supplier_price = COALESCE(@supplierPrice, supplier_price),
          updated_at = now()
        WHERE id = @id
        RETURNING $_returning
      '''),
      parameters: {
        'id': id,
        'name': name,
        'detail': detail,
        'sku': sku,
        'threshold': lowStockThreshold,
        'salePrice': salePrice,
        'minPrice': minPrice,
        'supplierPrice': supplierPrice,
      },
    );
    return _map(result.first);
  }

  @override
  Future<void> delete(String id) async {
    await _db.execute(
      Sql.named('DELETE FROM products WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  // Extra read columns appended after $_cols (index 9+): stock, image flag,
  // and an image "version" (epoch seconds) used to cache-bust the image URL.
  static const _readExtras = 'COALESCE(ps.current_stock, 0), '
      '(pi.product_id IS NOT NULL) AS has_image, '
      'COALESCE(extract(epoch FROM pi.updated_at)::bigint, 0) AS image_version';

  static const _readJoins =
      'LEFT JOIN product_stock ps ON ps.product_id = p.id '
      'LEFT JOIN product_images pi ON pi.product_id = p.id';

  @override
  Future<List<ProductWithStock>> listWithStock() async {
    final result = await _db.execute('''
      SELECT $_cols, $_readExtras
      FROM products p
      $_readJoins
      ORDER BY p.name, p.detail
    ''');
    return result.map(_mapWithStock).toList();
  }

  @override
  Future<ProductWithStock?> findByCode(String code) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT $_cols, $_readExtras
        FROM products p
        $_readJoins
        WHERE p.sku = @code
      '''),
      parameters: {'code': code},
    );
    if (result.isEmpty) return null;
    return _mapWithStock(result.first);
  }

  @override
  Future<List<ModelSize>> modelSizes(String modelId) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT p.id, p.detail, COALESCE(ps.current_stock, 0)
        FROM products p
        LEFT JOIN product_stock ps ON ps.product_id = p.id
        WHERE p.model_id = @modelId
        ORDER BY p.detail
      '''),
      parameters: {'modelId': modelId},
    );
    return result
        .map(
          (row) => ModelSize(
            productId: row[0].toString(),
            label: (row[1] as String?) ?? '',
            currentStock: row[2]! as int,
          ),
        )
        .toList();
  }

  ProductWithStock _mapWithStock(ResultRow row) => ProductWithStock(
        product: _map(row),
        currentStock: row[9]! as int,
        hasImage: row[10]! as bool,
        imageVersion: row[11]! as int,
      );

  Product _map(ResultRow row) => Product(
        id: row[0].toString(),
        name: row[1]! as String,
        detail: row[2] as String?,
        sku: row[3]! as String,
        lowStockThreshold: row[4]! as int,
        salePrice: row[5] as double?,
        minPrice: row[6] as double?,
        supplierPrice: row[7] as double?,
        modelId: row[8]?.toString(),
      );
}
