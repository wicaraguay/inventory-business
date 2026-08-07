import 'dart:io';

import 'package:inventy_backend/src/application/create_user.dart';
import 'package:inventy_backend/src/domain/ports/user_repository.dart';

/// On first boot, creates the initial owner from env vars if there are no users
/// yet: OWNER_USERNAME, OWNER_PASSWORD, OWNER_NAME (all optional, with defaults).
class BootstrapOwner {
  BootstrapOwner(this._users, this._createUser);

  final UserRepository _users;
  final CreateUser _createUser;

  Future<void> call() async {
    if (await _users.count() > 0) return;
    final env = Platform.environment;
    // Treat missing OR empty env vars as "use the default".
    String or(String? v, String fallback) =>
        (v ?? '').trim().isEmpty ? fallback : v!.trim();
    await _createUser.call(
      username: or(env['OWNER_USERNAME'], 'dueno'),
      password: (env['OWNER_PASSWORD'] ?? '').isEmpty
          ? 'admin1234'
          : env['OWNER_PASSWORD']!,
      role: 'owner',
      displayName: or(env['OWNER_NAME'], 'Dueño'),
    );
  }
}
