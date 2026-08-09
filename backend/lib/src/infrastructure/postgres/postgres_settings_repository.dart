import 'dart:typed_data';

import 'package:inventy_backend/src/domain/entities/app_settings.dart';
import 'package:inventy_backend/src/domain/entities/product_image.dart';
import 'package:inventy_backend/src/domain/ports/settings_repository.dart';
import 'package:postgres/postgres.dart';

/// ADAPTER: the single-row app_settings table on Postgres (+ business logo).
class PostgresSettingsRepository implements SettingsRepository {
  PostgresSettingsRepository(this._db);

  final Connection _db;

  static const _cols = 'business_name, default_threshold, '
      '(logo IS NOT NULL) AS has_logo, '
      'COALESCE(extract(epoch FROM logo_updated_at)::bigint, 0) AS logo_version';

  @override
  Future<AppSettings> get() async {
    final result = await _db.execute(
      'SELECT $_cols FROM app_settings WHERE id = 1',
    );
    if (result.isEmpty) {
      return AppSettings(businessName: 'Inventy', defaultThreshold: 0);
    }
    return _map(result.first);
  }

  @override
  Future<AppSettings> save({
    required String businessName,
    required int defaultThreshold,
  }) async {
    final result = await _db.execute(
      Sql.named('''
        UPDATE app_settings
        SET business_name = @name, default_threshold = @threshold,
            updated_at = now()
        WHERE id = 1
        RETURNING $_cols
      '''),
      parameters: {'name': businessName, 'threshold': defaultThreshold},
    );
    return _map(result.first);
  }

  @override
  Future<ProductImage?> getLogo() async {
    final result = await _db.execute(
      'SELECT logo FROM app_settings WHERE id = 1 AND logo IS NOT NULL',
    );
    if (result.isEmpty) return null;
    return ProductImage(
      data: result.first[0]! as Uint8List,
      contentType: 'image/jpeg',
    );
  }

  @override
  Future<void> saveLogo(Uint8List data, String contentType) async {
    await _db.execute(
      Sql.named(
        'UPDATE app_settings SET logo = @data, logo_updated_at = now() '
        'WHERE id = 1',
      ),
      parameters: {'data': data},
    );
  }

  @override
  Future<void> deleteLogo() async {
    await _db.execute(
      'UPDATE app_settings SET logo = NULL, logo_updated_at = NULL WHERE id = 1',
    );
  }

  @override
  Future<String?> discountPinHash() async {
    final result = await _db.execute(
      'SELECT discount_pin_hash FROM app_settings WHERE id = 1',
    );
    if (result.isEmpty) return null;
    return result.first[0] as String?;
  }

  @override
  Future<void> setDiscountPin(String pinHash) async {
    await _db.execute(
      Sql.named(
        'UPDATE app_settings SET discount_pin_hash = @h, updated_at = now() '
        'WHERE id = 1',
      ),
      parameters: {'h': pinHash},
    );
  }

  AppSettings _map(ResultRow row) => AppSettings(
        businessName: row[0]! as String,
        defaultThreshold: row[1]! as int,
        hasLogo: row[2]! as bool,
        logoVersion: row[3]! as int,
      );
}
