import 'package:inventy_backend/src/domain/exceptions.dart';
import 'package:inventy_backend/src/domain/ports/user_repository.dart';

/// Use case: delete a user. Refuses to delete the last remaining owner so the
/// system is never left without an administrator.
class DeleteUser {
  DeleteUser(this._users);

  final UserRepository _users;

  Future<void> call(String id, {required String requestedByUserId}) async {
    if (id == requestedByUserId) {
      throw DomainException('No podés eliminar tu propia cuenta');
    }
    await _users.delete(id);
  }
}
