import 'package:dio/dio.dart';
import 'package:inventy_app/features/auth/domain/auth_user.dart';

class HttpAuthRepository {
  HttpAuthRepository(this._dio);

  final Dio _dio;

  Future<({String token, AuthUser user})> login(
    String username,
    String password,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'username': username, 'password': password},
    );
    final data = res.data!;
    return (
      token: data['token'] as String,
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  /// Validates the current token; returns the user or null if invalid.
  Future<AuthUser?> me() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/auth/me');
      return AuthUser.fromJson(res.data!);
    } catch (_) {
      return null;
    }
  }

  /// Changes the logged-in user's own password.
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _dio.post<Map<String, dynamic>>(
      '/auth/change-password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  /// Authorizes a below-list discount with the discount PIN (or an owner's
  /// password). Returns whether it's ok and who authorized (owner name, or null
  /// when the shared PIN was used).
  Future<({bool ok, String? by})> authorizeDiscount(String secret) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/authorize-discount',
        data: {'password': secret},
      );
      return (ok: true, by: res.data?['by'] as String?);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) return (ok: false, by: null);
      rethrow;
    }
  }
}
