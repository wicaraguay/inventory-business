import 'package:inventy_backend/src/domain/entities/user.dart';

/// A user together with its stored password hash (only for login checks).
class UserWithHash {
  UserWithHash(this.user, this.passwordHash);
  final User user;
  final String passwordHash;
}

/// PORT: persistence contract for system users.
abstract interface class UserRepository {
  Future<UserWithHash?> findByUsername(String username);

  Future<User> create({
    required String username,
    required String passwordHash,
    required String role,
    required String displayName,
  });

  Future<List<User>> list();

  Future<void> delete(String id);

  /// Sets a new password hash for the given user (used by "change my password").
  Future<void> updatePassword(String id, String passwordHash);

  /// How many users exist (used to seed the first owner).
  Future<int> count();

  Future<bool> usernameExists(String username);
}
