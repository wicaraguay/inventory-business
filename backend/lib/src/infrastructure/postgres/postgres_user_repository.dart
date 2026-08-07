import 'package:inventy_backend/src/domain/entities/user.dart';
import 'package:inventy_backend/src/domain/ports/user_repository.dart';
import 'package:postgres/postgres.dart';

/// ADAPTER: system users on Postgres.
class PostgresUserRepository implements UserRepository {
  PostgresUserRepository(this._db);

  final Connection _db;

  static const _cols =
      'id, username, role, display_name, can_manage_inventory';

  @override
  Future<UserWithHash?> findByUsername(String username) async {
    final result = await _db.execute(
      Sql.named(
        'SELECT $_cols, password_hash FROM users WHERE username = @u',
      ),
      parameters: {'u': username},
    );
    if (result.isEmpty) return null;
    final row = result.first;
    return UserWithHash(_map(row), row[5]! as String);
  }

  @override
  Future<User?> findById(String id) async {
    final result = await _db.execute(
      Sql.named('SELECT $_cols FROM users WHERE id = @id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return _map(result.first);
  }

  @override
  Future<User> create({
    required String username,
    required String passwordHash,
    required String role,
    required String displayName,
    bool canManageInventory = false,
  }) async {
    final result = await _db.execute(
      Sql.named('''
        INSERT INTO users (username, password_hash, role, display_name,
                           can_manage_inventory)
        VALUES (@u, @h, @r, @n, @c)
        RETURNING $_cols
      '''),
      parameters: {
        'u': username,
        'h': passwordHash,
        'r': role,
        'n': displayName,
        'c': canManageInventory,
      },
    );
    return _map(result.first);
  }

  @override
  Future<User> update({
    required String id,
    required String username,
    required String role,
    required String displayName,
    required bool canManageInventory,
  }) async {
    final result = await _db.execute(
      Sql.named('''
        UPDATE users
        SET username = @u, role = @r, display_name = @n,
            can_manage_inventory = @c
        WHERE id = @id
        RETURNING $_cols
      '''),
      parameters: {
        'id': id,
        'u': username,
        'r': role,
        'n': displayName,
        'c': canManageInventory,
      },
    );
    return _map(result.first);
  }

  @override
  Future<List<User>> list() async {
    final result = await _db.execute(
      'SELECT $_cols FROM users ORDER BY role, display_name',
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
  Future<int> countOwners() async {
    final result = await _db.execute(
      "SELECT count(*)::int FROM users WHERE role = 'owner'",
    );
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
        canManageInventory: row[4]! as bool,
      );
}
