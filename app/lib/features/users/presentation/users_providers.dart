import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/auth/domain/auth_user.dart';
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
  }) async {
    await ref.read(usersRepositoryProvider).create(
          username: username,
          password: password,
          role: role,
          displayName: displayName,
        );
    ref.invalidateSelf();
    await future;
  }

  Future<void> remove(String id) async {
    await ref.read(usersRepositoryProvider).delete(id);
    ref.invalidateSelf();
    await future;
  }
}

final usersProvider =
    AsyncNotifierProvider<UsersNotifier, List<AuthUser>>(UsersNotifier.new);
