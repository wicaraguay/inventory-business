import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:inventy_app/features/settings/domain/settings.dart';
import 'package:inventy_app/features/settings/domain/settings_repository.dart';

class HttpSettingsRepository implements SettingsRepository {
  HttpSettingsRepository(this._dio);

  final Dio _dio;

  @override
  Future<Settings> fetch() async {
    final res = await _dio.get<Map<String, dynamic>>('/settings');
    return _map(res.data!);
  }

  @override
  Future<Settings> save(Settings settings) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/settings',
      data: {
        'businessName': settings.businessName,
        'defaultThreshold': settings.defaultThreshold,
      },
    );
    return _map(res.data!);
  }

  @override
  Future<void> saveLogo(Uint8List bytes) async {
    await _dio.put<void>(
      '/settings/logo',
      data: Stream.fromIterable([bytes]),
      options: Options(
        contentType: 'image/jpeg',
        headers: {Headers.contentLengthHeader: bytes.length},
      ),
    );
  }

  @override
  Future<void> deleteLogo() async {
    await _dio.delete<void>('/settings/logo');
  }

  @override
  Future<void> setDiscountPin(String pin) async {
    await _dio.put<void>('/settings/discount-pin', data: {'pin': pin});
  }

  Settings _map(Map<String, dynamic> json) => Settings(
        businessName: json['businessName'] as String,
        defaultThreshold: json['defaultThreshold'] as int,
        hasLogo: json['hasLogo'] as bool? ?? false,
        logoVersion: json['logoVersion'] as int? ?? 0,
      );
}
