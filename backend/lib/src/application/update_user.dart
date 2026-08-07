import 'package:inventy_backend/src/domain/entities/user.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';
import 'package:inventy_backend/src/domain/ports/user_repository.dart';
import 'package:inventy_backend/src/infrastructure/auth/password_hasher.dart';

/// Use case: the owner edits a user (name, username, role, inventory permission)
/// and optionally resets their password. Guards against locking the shop out of
/// its last owner.
class UpdateUser {
  UpdateUser(this._users, this._hasher);

  final UserRepository _users;
  final PasswordHasher _hasher;

  Future<User> call({
    required String id,
    required String username,
    required String role,
    required String displayName,
    required bool canManageInventory,
    String? newPassword,
  }) async {
    final user = username.trim();
    if (user.isEmpty) throw DomainException('El usuario es obligatorio');
    if (role != 'owner' && role != 'employee') {
      throw DomainException('Rol inválido');
    }

    final current = await _users.findById(id);
    if (current == null) throw DomainException('El usuario no existe');

    // Username must stay unique (but the user may keep their own).
    if (user != current.username && await _users.usernameExists(user)) {
      throw DomainException('Ese usuario ya existe');
    }

    // Never leave the shop without an owner.
    if (current.isOwner && role != 'owner' && await _users.countOwners() <= 1) {
      throw DomainException('Debe haber al menos un dueño');
    }

    // Optional password reset (owner forcing a new one, e.g. employee forgot it).
    if (newPassword != null && newPassword.isNotEmpty) {
      if (newPassword.length < 4) {
        throw DomainException(
          'La contraseña debe tener al menos 4 caracteres',
        );
      }
      await _users.updatePassword(id, _hasher.hash(newPassword));
    }

    final name = displayName.trim().isEmpty ? user : displayName.trim();
    return _users.update(
      id: id,
      username: user,
      role: role,
      displayName: name,
      canManageInventory: role == 'employee' && canManageInventory,
    );
  }
}
