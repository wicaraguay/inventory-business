import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base URL of the backend API. Override at build time with:
///   --dart-define=API_BASE_URL=https://tu-servidor/api
const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8090',
);

/// The current session token (set by the auth controller after login, cleared
/// on logout). Sent as a Bearer token on every API call AND on image loads.
String? authToken;

/// Authorization header for API requests and Image.network image loads.
Map<String, String> get apiAuthHeaders =>
    authToken == null ? const {} : {'Authorization': 'Bearer $authToken'};

/// The backend base URL, for building plain URLs (e.g. product image `<img>`
/// sources loaded with Image.network, which don't go through Dio).
final apiBaseUrlProvider = Provider<String>((ref) => _baseUrl);

/// Single shared Dio instance. An interceptor attaches the session token.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = authToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );
  return dio;
});
