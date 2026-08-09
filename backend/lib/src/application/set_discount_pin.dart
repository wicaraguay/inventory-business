import 'package:inventy_backend/src/domain/exceptions.dart';
import 'package:inventy_backend/src/domain/ports/settings_repository.dart';
import 'package:inventy_backend/src/infrastructure/auth/password_hasher.dart';

/// Use case: the owner sets (or changes) the discount PIN. Stored hashed.
class SetDiscountPin {
  SetDiscountPin(this._settings, this._hasher);

  final SettingsRepository _settings;
  final PasswordHasher _hasher;

  Future<void> call(String pin) async {
    final p = pin.trim();
    if (p.length < 4) {
      throw DomainException('El PIN debe tener al menos 4 dígitos');
    }
    await _settings.setDiscountPin(_hasher.hash(p));
  }
}
