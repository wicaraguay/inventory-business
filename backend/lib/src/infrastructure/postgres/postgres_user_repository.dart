import 'package:inventy_backend/src/domain/entities/user.dart';
import 'package:inventy_backend/src/domain/ports/user_repository.dart';
import 'package:postgres/postgres.dart';

/// ADAPTER: system users on Postgres.
class PostgresUserRepository implements UserRepository {
  PostgresUserRepository(this._db);

  final Connection _db;

  @override
  Future<UserWithHash?> findByUsername(String username) async {
    final result = await _db.execute(
      Sql.named(
        'SELECT id, username, role, display_name, password_hash '
        'FROM users WHERE username = @u',
      ),
      parameters: {'u': username},
    );
    if (result.isEmpty) return null;
    final row = result.first;
    return UserWithHash(_map(row), row[4]! as String);
  }

  @override
  Future<User> create({
    required String username,
    required String passwordHash,
    required String role,
    required String displayName,
  }) async {
    final result = await _db.execute(
      Sql.named('''
        INSERT INTO users (username, password_hash, role, display_name)
        VALUES (@u, @h, @r, @n)
        RETURNING id, username, role, display_name
      '''),
      parameters: {
        'u': username,
        'h': passwordHash,
        'r': role,
        'n': displayName,
      },
    );
    return _map(result.first);
  }

  @override
  Future<List<User>> list() async {
    final result = await _db.execute(
      'SELECT id, username, role, display_name FROM users '
      'ORDER BY role, display_name',
    );
    return result.map(_map).toList();
  }

  @override
  Future<void> delete(String id) async {
    await _db.execute(
      Sql.named('DELETE FROM users WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  @override
  Future<void> updatePassword(String id, String passwordHash) async {
    await _db.execute(
      Sql.named('UPDATE users SET password_hash = @h WHERE id = @id'),
      parameters: {'h': passwordHash, 'id': id},
    );
  }

  @override
  Future<int> count() async {
    final result = await _db.execute('SELECT count(*)::int FROM users');
    return result.first[0]! as int;
  }

  @override
  Future<bool> usernameExists(String username) async {
    final result = await _db.execute(
      Sql.named('SELECT 1 FROM users WHERE username = @u'),
      parameters: {'u': username},
    );
    return result.isNotEmpty;
  }

  User _map(ResultRow row) => User(
        id: row[0].toString(),
        username: row[1]! as String,
        role: row[2]! as String,
        displayName: row[3]! as String,
      );
}
