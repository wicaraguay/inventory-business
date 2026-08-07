import 'package:inventy_backend/src/domain/entities/user.dart';
import 'package:inventy_backend/src/domain/ports/user_repository.dart';

/// Use case: list all system users.
class ListUsers {
  ListUsers(this._users);

  final UserRepository _users;

  Future<List<User>> call() => _users.list();
}
