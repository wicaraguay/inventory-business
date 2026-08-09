import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/auth/domain/auth_user.dart';
import 'package:inventy_app/features/auth/presentation/auth_providers.dart';
import 'package:inventy_app/features/users/data/http_users_repository.dart';
import 'package:inventy_app/shared/api/api_client.dart';

final usersRepositoryProvider = Provider<HttpUsersRepository>(
  (ref) => HttpUsersRepository(ref.watch(dioProvider)),
);

class UsersNotifier extends AsyncNotifier<List<AuthUser>> {
  @override
  Future<List<AuthUser>> build() => ref.watch(usersRepositoryProvider).list();

  Future<void> create({
    required String username,
    required String password,
    required String role,
    required String displayName,
    required bool canManageInventory,
  }) async {
    await ref.read(usersRepositoryProvider).create(
          username: username,
          password: password,
          role: role,
          displayName: displayName,
          canManageInventory: canManageInventory,
        );
    ref.invalidateSelf();
    await future;
  }

  Future<void> edit({
    required String id,
    required String username,
    required String role,
    required String displayName,
    required bool canManageInventory,
    String? newPassword,
  }) async {
    final res = await ref.read(usersRepositoryProvider).update(
          id: id,
          username: username,
          role: role,
          displayName: displayName,
          canManageInventory: canManageInventory,
          newPassword: newPassword,
        );
    // Editing your OWN profile returns a fresh token: adopt it so the sidebar
    // and everything else show the new name/role right away.
    if (res.token != null) {
      await ref.read(authProvider.notifier).adoptSession(res.user, res.token!);
    }
    ref.invalidateSelf();
    await future;
  }

  Future<void> remove(String id) async {
    await ref.read(usersRepositoryProvider).delete(id);
    // Drop it from the in-memory list rather than refetching (a refetch that
    // errors could blank the screen — same fix as products).
    final current = state.asData?.value ?? const <AuthUser>[];
    state = AsyncData([for (final u in current) if (u.id != id) u]);
  }
}

final usersProvider =
    AsyncNotifierProvider<UsersNotifier, List<AuthUser>>(UsersNotifier.new);
