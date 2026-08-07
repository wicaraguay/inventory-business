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

  Future<User?> findById(String id);

  Future<User> create({
    required String username,
    required String passwordHash,
    required String role,
    required String displayName,
    bool canManageInventory = false,
  });

  /// Edits a user's profile (not the password — see [updatePassword]).
  Future<User> update({
    required String id,
    required String username,
    required String role,
    required String displayName,
    required bool canManageInventory,
  });

  Future<List<User>> list();

  Future<void> delete(String id);

  /// Sets a new password hash for the given user (used by "change my password"
  /// and by the owner resetting an employee's password).
  Future<void> updatePassword(String id, String passwordHash);

  /// How many users exist (used to seed the first owner).
  Future<int> count();

  /// How many owners exist (used to refuse removing the last one).
  Future<int> countOwners();

  Future<bool> usernameExists(String username);
}
