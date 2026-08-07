import 'package:dio/dio.dart';
import 'package:inventy_app/features/auth/domain/auth_user.dart';

class HttpUsersRepository {
  HttpUsersRepository(this._dio);

  final Dio _dio;

  Future<List<AuthUser>> list() async {
    final res = await _dio.get<Map<String, dynamic>>('/users');
    final items = (res.data!['users'] as List).cast<Map<String, dynamic>>();
    return items.map(AuthUser.fromJson).toList();
  }

  Future<AuthUser> create({
    required String username,
    required String password,
    required String role,
    required String displayName,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/users',
      data: {
        'username': username,
        'password': password,
        'role': role,
        'displayName': displayName,
      },
    );
    return AuthUser.fromJson(res.data!);
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('/users/$id');
  }
}
