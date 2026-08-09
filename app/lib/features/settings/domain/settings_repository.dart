import 'dart:typed_data';

import 'package:inventy_app/features/settings/domain/settings.dart';

/// Reads/writes the shared business settings (stored in the backend so every
/// device sees the same values).
abstract interface class SettingsRepository {
  Future<Settings> fetch();

  Future<Settings> save(Settings settings);

  /// Uploads the business logo (JPEG bytes). Owner-only on the backend.
  Future<void> saveLogo(Uint8List bytes);

  /// Removes the business logo.
  Future<void> deleteLogo();

  /// Sets/changes the discount PIN (owner-only).
  Future<void> setDiscountPin(String pin);
}
