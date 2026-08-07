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

  Settings _map(Map<String, dynamic> json) => Settings(
        businessName: json['businessName'] as String,
        defaultThreshold: json['defaultThreshold'] as int,
      );
}
