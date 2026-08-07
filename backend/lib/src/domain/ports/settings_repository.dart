import 'package:inventy_backend/src/domain/entities/app_settings.dart';

/// PORT: persistence contract for the shared business settings.
abstract interface class SettingsRepository {
  Future<AppSettings> get();

  Future<AppSettings> save({
    required String businessName,
    required int defaultThreshold,
  });
}
