import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base URL of the backend API. Override at run/build time with:
///   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8090
/// Default host port is 8090 (8080 is used by another local project).
const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8090',
);

/// The backend base URL, for building plain URLs (e.g. product image `<img>`
/// sources loaded with Image.network, which don't go through Dio).
final apiBaseUrlProvider = Provider<String>((ref) => _baseUrl);

/// Single shared Dio instance. The app talks ONLY to the backend, never to
/// Postgres directly.
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );
});
