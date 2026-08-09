import 'package:inventy_backend/src/domain/entities/user.dart';
import 'package:inventy_backend/src/domain/ports/user_repository.dart';
import 'package:inventy_backend/src/infrastructure/auth/password_hasher.dart';

/// Use case: verify that a typed password belongs to an owner — used at the
/// register to authorize a below-list-price discount. Returns the matching
/// owner (so we know who authorized), or null if the password is wrong.
class AuthorizeOwner {
  AuthorizeOwner(this._users, this._hasher);

  final UserRepository _users;
  final PasswordHasher _hasher;

  Future<User?> call(String password) async {
    if (password.isEmpty) return null;
    final owners = await _users.ownersWithHash();
    for (final o in owners) {
      if (_hasher.verify(password, o.passwordHash)) return o.user;
    }
    return null;
  }
}
