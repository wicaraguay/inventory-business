import 'package:inventy_app/features/settings/domain/settings.dart';

/// Reads/writes the shared business settings (stored in the backend so every
/// device sees the same values).
abstract interface class SettingsRepository {
  Future<Settings> fetch();

  Future<Settings> save(Settings settings);
}
