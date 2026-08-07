import 'package:inventy_backend/src/domain/entities/user.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';
import 'package:inventy_backend/src/domain/ports/user_repository.dart';
import 'package:inventy_backend/src/infrastructure/auth/password_hasher.dart';

/// Use case: create a system user (owner or employee).
class CreateUser {
  CreateUser(this._users, this._hasher);

  final UserRepository _users;
  final PasswordHasher _hasher;

  Future<User> call({
    required String username,
    required String password,
    required String role,
    required String displayName,
  }) async {
    final user = username.trim();
    if (user.isEmpty) throw DomainException('El usuario es obligatorio');
    if (password.length < 4) {
      throw DomainException('La contraseña debe tener al menos 4 caracteres');
    }
    if (role != 'owner' && role != 'employee') {
      throw DomainException('Rol inválido');
    }
    if (await _users.usernameExists(user)) {
      throw DomainException('Ese usuario ya existe');
    }
    final name = displayName.trim().isEmpty ? user : displayName.trim();
    return _users.create(
      username: user,
      passwordHash: _hasher.hash(password),
      role: role,
      displayName: name,
    );
  }
}
