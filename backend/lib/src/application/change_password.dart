import 'package:inventy_backend/src/domain/entities/user.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';
import 'package:inventy_backend/src/domain/ports/user_repository.dart';
import 'package:inventy_backend/src/infrastructure/auth/password_hasher.dart';

/// Use case: a logged-in user changes their OWN password. Requires the current
/// password so a stolen/forgotten session can't silently lock the account.
class ChangePassword {
  ChangePassword(this._users, this._hasher);

  final UserRepository _users;
  final PasswordHasher _hasher;

  Future<void> call({
    required User current,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 4) {
      throw DomainException(
        'La nueva contraseña debe tener al menos 4 caracteres',
      );
    }
    final found = await _users.findByUsername(current.username);
    if (found == null) {
      throw DomainException('Usuario no encontrado');
    }
    if (!_hasher.verify(currentPassword, found.passwordHash)) {
      throw DomainException('La contraseña actual no es correcta');
    }
    await _users.updatePassword(found.user.id, _hasher.hash(newPassword));
  }
}
