import 'dart:typed_data';

import 'package:inventy_backend/src/domain/entities/app_settings.dart';
import 'package:inventy_backend/src/domain/entities/product_image.dart';

/// PORT: persistence contract for the shared business settings (+ logo).
abstract interface class SettingsRepository {
  Future<AppSettings> get();

  Future<AppSettings> save({
    required String businessName,
    required int defaultThreshold,
  });

  /// The business logo, or null if none was uploaded.
  Future<ProductImage?> getLogo();

  Future<void> saveLogo(Uint8List data, String contentType);

  Future<void> deleteLogo();
}
