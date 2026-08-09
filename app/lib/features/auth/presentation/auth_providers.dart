import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/auth/data/http_auth_repository.dart';
import 'package:inventy_app/features/auth/domain/auth_user.dart';
import 'package:inventy_app/features/settings/presentation/settings_providers.dart';
import 'package:inventy_app/shared/api/api_client.dart';

final authRepositoryProvider = Provider<HttpAuthRepository>(
  (ref) => HttpAuthRepository(ref.watch(dioProvider)),
);

class AuthState {
  const AuthState({this.user});
  final AuthUser? user;
  bool get isAuthenticated => user != null;
}

class AuthController extends Notifier<AuthState> {
  static const _kToken = 'auth_token';
  static const _kUser = 'auth_user';

  @override
  AuthState build() {
    // Restore a saved session (optimistic): set the token and validate in the
    // background — if it's no longer valid, we log out.
    final prefs = ref.read(sharedPreferencesProvider);
    final token = prefs.getString(_kToken);
    final userJson = prefs.getString(_kUser);
    if (token != null && userJson != null) {
      authToken = token;
      _validate();
      return AuthState(
        user: AuthUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>),
      );
    }
    return const AuthState();
  }

  Future<void> _validate() async {
    final me = await ref.read(authRepositoryProvider).me();
    if (me == null) {
      await logout();
    } else {
      state = AuthState(user: me);
    }
  }

  /// Logs in; throws with a friendly message on bad credentials.
  Future<void> login(String username, String password) async {
    try {
      final result =
          await ref.read(authRepositoryProvider).login(username, password);
      authToken = result.token;
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_kToken, result.token);
      await prefs.setString(_kUser, jsonEncode(result.user.toJson()));
      state = AuthState(user: result.user);
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['error'] as String?
          : null;
      throw Exception(msg ?? 'No se pudo iniciar sesión. Revisá la conexión.');
    }
  }

  /// Changes the current user's password; throws with a friendly message.
  Future<void> changePassword(String current, String newPassword) async {
    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(current, newPassword);
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['error'] as String?
          : null;
      throw Exception(msg ?? 'No se pudo cambiar la contraseña. Revisá la conexión.');
    }
  }

  /// Adopts a freshly re-issued session — used after you edit your OWN profile,
  /// so the new name/role appears everywhere without re-logging in.
  Future<void> adoptSession(AuthUser user, String token) async {
    authToken = token;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kToken, token);
    await prefs.setString(_kUser, jsonEncode(user.toJson()));
    state = AuthState(user: user);
  }

  Future<void> logout() async {
    authToken = null;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_kToken);
    await prefs.remove(_kUser);
    state = const AuthState();
  }
}

final authProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

final currentUserProvider =
    Provider<AuthUser?>((ref) => ref.watch(authProvider).user);

final isAuthenticatedProvider =
    Provider<bool>((ref) => ref.watch(authProvider).user != null);
