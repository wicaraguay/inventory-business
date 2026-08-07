import 'dart:typed_data';

import 'package:inventy_backend/src/domain/entities/product_image.dart';
import 'package:inventy_backend/src/domain/ports/product_image_repository.dart';
import 'package:postgres/postgres.dart';

/// ADAPTER: product images stored inline (bytea) in Postgres.
class PostgresProductImageRepository implements ProductImageRepository {
  PostgresProductImageRepository(this._db);

  final Connection _db;

  @override
  Future<ProductImage?> find(String productId) async {
    final result = await _db.execute(
      Sql.named(
        'SELECT data, content_type FROM product_images WHERE product_id = @id',
      ),
      parameters: {'id': productId},
    );
    if (result.isEmpty) return null;
    final row = result.first;
    return ProductImage(
      data: row[0]! as Uint8List,
      contentType: row[1]! as String,
    );
  }

  @override
  Future<void> save(
    String productId,
    Uint8List data,
    String contentType,
  ) async {
    await _db.execute(
      Sql.named('''
        INSERT INTO product_images (product_id, data, content_type, updated_at)
        VALUES (@id, @data, @contentType, now())
        ON CONFLICT (product_id) DO UPDATE
          SET data = excluded.data,
              content_type = excluded.content_type,
              updated_at = now()
      '''),
      parameters: {
        'id': productId,
        // A Uint8List value is encoded as bytea by the driver.
        'data': data,
        'contentType': contentType,
      },
    );
  }

  @override
  Future<void> delete(String productId) async {
    await _db.execute(
      Sql.named('DELETE FROM product_images WHERE product_id = @id'),
      parameters: {'id': productId},
    );
  }
}
