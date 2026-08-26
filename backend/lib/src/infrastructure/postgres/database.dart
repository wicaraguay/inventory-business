import 'dart:io';

import 'package:postgres/postgres.dart';

/// Lazily opens a single shared Postgres connection from environment config.
/// Credentials live server-side only — the Flutter client never sees them.
class Database {
  Database._();

  static Connection? _connection;

  static Future<Connection> connection() async {
    if (_connection != null) return _connection!;

    final conn = await Connection.open(
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? 'postgres',
        port: int.tryParse(Platform.environment['DB_PORT'] ?? '') ?? 5432,
        database: Platform.environment['DB_NAME'] ?? 'inventy',
        username: Platform.environment['DB_USER'] ?? 'inventy',
        password: Platform.environment['DB_PASSWORD'] ?? '',
      ),
      // Local Docker network: no TLS between containers.
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );

    // Compute dates in the BUSINESS timezone (not the server's UTC), so
    // `current_date`, `created_at::date` and `date_trunc` follow local time.
    // Fixes "sold today" resetting at UTC midnight and day-grouping in reports.
    // Parameterised via set_config to avoid any SQL injection from the env var.
    final tz = Platform.environment['APP_TIMEZONE'] ?? 'America/Guayaquil';
    await conn.execute(
      Sql.named("SELECT set_config('TimeZone', @tz, false)"),
      parameters: {'tz': tz},
    );

    return _connection = conn;
  }
}
