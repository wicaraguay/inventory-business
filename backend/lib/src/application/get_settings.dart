import 'package:inventy_backend/src/domain/entities/app_settings.dart';
import 'package:inventy_backend/src/domain/ports/settings_repository.dart';

/// Use case: read the shared business settings.
class GetSettings {
  GetSettings(this._repository);

  final SettingsRepository _repository;

  Future<AppSettings> call() => _repository.get();
}
