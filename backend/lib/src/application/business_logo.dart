import 'dart:typed_data';

import 'package:inventy_backend/src/domain/entities/product_image.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';
import 'package:inventy_backend/src/domain/ports/settings_repository.dart';

/// Use cases for the business logo (read/save/delete).
class GetBusinessLogo {
  GetBusinessLogo(this._settings);
  final SettingsRepository _settings;
  Future<ProductImage?> call() => _settings.getLogo();
}

class SaveBusinessLogo {
  SaveBusinessLogo(this._settings);
  final SettingsRepository _settings;

  static const _maxBytes = 5 * 1024 * 1024;

  Future<void> call(Uint8List data, String contentType) async {
    if (data.isEmpty) throw DomainException('La imagen está vacía');
    if (data.length > _maxBytes) {
      throw DomainException('La imagen es demasiado grande');
    }
    await _settings.saveLogo(data, contentType);
  }
}

class DeleteBusinessLogo {
  DeleteBusinessLogo(this._settings);
  final SettingsRepository _settings;
  Future<void> call() => _settings.deleteLogo();
}
