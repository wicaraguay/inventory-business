import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:inventy_backend/src/domain/entities/user.dart';

/// Signs and verifies JWTs for the login session. Uses JWT_SECRET from the env.
class JwtService {
  JwtService([String? secret])
      : _secret = secret ??
            Platform.environment['JWT_SECRET'] ??
            'dev_secret_change_me';

  final String _secret;

  String sign(User user) {
    final jwt = JWT({
      'id': user.id,
      'username': user.username,
      'role': user.role,
      'name': user.displayName,
    });
    return jwt.sign(SecretKey(_secret), expiresIn: const Duration(days: 30));
  }

  /// Returns the user encoded in a valid token, or null if invalid/expired.
  User? verify(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_secret));
      final p = jwt.payload as Map<String, dynamic>;
      return User(
        id: p['id'] as String,
        username: p['username'] as String,
        role: p['role'] as String,
        displayName: p['name'] as String,
      );
    } catch (_) {
      return null;
    }
  }
}
