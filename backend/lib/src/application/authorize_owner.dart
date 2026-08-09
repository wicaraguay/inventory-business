import 'package:inventy_backend/src/domain/ports/settings_repository.dart';
import 'package:inventy_backend/src/domain/ports/user_repository.dart';
import 'package:inventy_backend/src/infrastructure/auth/password_hasher.dart';

/// Use case: authorize a below-list discount at the register. It accepts either
/// the shared discount PIN (so an employee can use it when the owner is away)
/// OR an owner's login password (owner present). Returns whether it's authorized
/// and, when known, WHO authorized (owner name; null for the shared PIN).
class AuthorizeOwner {
  AuthorizeOwner(this._users, this._settings, this._hasher);

  final UserRepository _users;
  final SettingsRepository _settings;
  final PasswordHasher _hasher;

  Future<({bool ok, String? by})> call(String secret) async {
    if (secret.isEmpty) return (ok: false, by: null);
    // 1) The dedicated discount PIN.
    final pin = await _settings.discountPinHash();
    if (pin != null && _hasher.verify(secret, pin)) {
      return (ok: true, by: null);
    }
    // 2) An owner's login password (owner present).
    final owners = await _users.ownersWithHash();
    for (final o in owners) {
      if (_hasher.verify(secret, o.passwordHash)) {
        return (ok: true, by: o.user.displayName);
      }
    }
    return (ok: false, by: null);
  }
}
