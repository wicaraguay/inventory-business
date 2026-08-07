import 'package:inventy_backend/src/domain/entities/app_settings.dart';
import 'package:inventy_backend/src/domain/ports/settings_repository.dart';
import 'package:postgres/postgres.dart';

/// ADAPTER: the single-row app_settings table on Postgres.
class PostgresSettingsRepository implements SettingsRepository {
  PostgresSettingsRepository(this._db);

  final Connection _db;

  @override
  Future<AppSettings> get() async {
    final result = await _db.execute(
      'SELECT business_name, default_threshold FROM app_settings WHERE id = 1',
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
        SET business_name = @name,
            default_threshold = @threshold,
            updated_at = now()
        WHERE id = 1
        RETURNING business_name, default_threshold
      '''),
      parameters: {'name': businessName, 'threshold': defaultThreshold},
    );
    return _map(result.first);
  }

  AppSettings _map(ResultRow row) => AppSettings(
        businessName: row[0]! as String,
        defaultThreshold: row[1]! as int,
      );
}
