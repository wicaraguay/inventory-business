import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base URL of the backend API. Override at run/build time with:
///   --dart-define=API_BASE_URL=https://inventy.tudominio.com/api
/// Default host port is 8090 (8080 is used by another local project).
const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8090',
);

/// Optional HTTP Basic credentials ("user:pass") for a reverse-proxy password.
/// Baked at build time with --dart-define=API_AUTH=user:pass. Empty = no auth
/// (local dev). Sent on every API call AND on image loads.
const _apiAuth = String.fromEnvironment('API_AUTH');

/// Authorization header for API requests and Image.network image loads, or
/// empty when no proxy password is configured.
final Map<String, String> apiAuthHeaders = _apiAuth.isEmpty
    ? const {}
    : {'Authorization': 'Basic ${base64Encode(utf8.encode(_apiAuth))}'};

/// The backend base URL, for building plain URLs (e.g. product image `<img>`
/// sources loaded with Image.network, which don't go through Dio).
final apiBaseUrlProvider = Provider<String>((ref) => _baseUrl);

/// Single shared Dio instance. The app talks ONLY to the backend, never to
/// Postgres directly.
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      // Higher timeouts than local: requests now travel over the internet.
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {...apiAuthHeaders},
    ),
  );
});
