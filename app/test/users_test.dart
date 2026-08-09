import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventy_app/features/auth/domain/auth_user.dart';
import 'package:inventy_app/features/auth/presentation/auth_providers.dart';
import 'package:inventy_app/features/settings/presentation/settings_providers.dart';
import 'package:inventy_app/features/users/data/http_users_repository.dart';
import 'package:inventy_app/features/users/presentation/users_providers.dart';
import 'package:inventy_app/features/users/presentation/users_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fake users repo — stateful so delete actually removes the user. Extends the
/// real repo with a throwaway Dio (never used; every method is overridden).
class _FakeUsersRepository extends HttpUsersRepository {
  _FakeUsersRepository() : super(Dio());

  final _users = <AuthUser>[
    const AuthUser(id: 'o1', username: 'nina', role: 'owner', displayName: 'Nina'),
    const AuthUser(
        id: 'e1', username: 'juan', role: 'employee', displayName: 'Juan'),
  ];

  @override
  Future<List<AuthUser>> list() async => List.of(_users);

  @override
  Future<void> delete(String id) async => _users.removeWhere((u) => u.id == id);
}

const _owner = AuthUser(
  id: 'o1',
  username: 'nina',
  role: 'owner',
  displayName: 'Nina',
);

void main() {
  testWidgets('el dueño borra un empleado y sale de la lista sin crashear', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          usersRepositoryProvider.overrideWithValue(_FakeUsersRepository()),
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUserProvider.overrideWithValue(_owner),
        ],
        child: const MaterialApp(home: Scaffold(body: UsersScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Juan'), findsOneWidget);

    // Only the employee (not self) has a delete button.
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    // Confirm.
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('Juan'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
