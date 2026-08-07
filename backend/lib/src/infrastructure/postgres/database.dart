import 'dart:io';

import 'package:postgres/postgres.dart';

/// Lazily opens a single shared Postgres connection from environment config.
/// Credentials live server-side only — the Flutter client never sees them.
class Database {
  Database._();

  static Connection? _connection;

  static Future<Connection> connection() async {
    return _connection ??= await Connection.open(
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
  }
}
