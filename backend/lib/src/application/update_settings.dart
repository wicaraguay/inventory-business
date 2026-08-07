import 'package:inventy_backend/src/domain/entities/app_settings.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';
import 'package:inventy_backend/src/domain/ports/settings_repository.dart';

/// Use case: update the shared business settings.
class UpdateSettings {
  UpdateSettings(this._repository);

  final SettingsRepository _repository;

  Future<AppSettings> call({
    required String businessName,
    required int defaultThreshold,
  }) async {
    final name = businessName.trim().isEmpty ? 'Inventy' : businessName.trim();
    if (defaultThreshold < 0) {
      throw DomainException('El umbral no puede ser negativo');
    }
    return _repository.save(
      businessName: name,
      defaultThreshold: defaultThreshold,
    );
  }
}
