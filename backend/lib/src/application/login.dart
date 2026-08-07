import 'package:inventy_backend/src/domain/entities/user.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';
import 'package:inventy_backend/src/domain/ports/user_repository.dart';
import 'package:inventy_backend/src/infrastructure/auth/jwt_service.dart';
import 'package:inventy_backend/src/infrastructure/auth/password_hasher.dart';

/// Use case: verify credentials and issue a session token.
class Login {
  Login(this._users, this._hasher, this._jwt);

  final UserRepository _users;
  final PasswordHasher _hasher;
  final JwtService _jwt;

  Future<({String token, User user})> call(
    String username,
    String password,
  ) async {
    if (username.trim().isEmpty || password.isEmpty) {
      throw DomainException('Usuario y contraseña son obligatorios');
    }
    final found = await _users.findByUsername(username.trim());
    if (found == null || !_hasher.verify(password, found.passwordHash)) {
      throw DomainException('Usuario o contraseña incorrectos');
    }
    return (token: _jwt.sign(found.user), user: found.user);
  }
}
