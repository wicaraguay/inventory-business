import 'package:bcrypt/bcrypt.dart';

/// Hashes and verifies passwords with bcrypt.
class PasswordHasher {
  String hash(String password) => BCrypt.hashpw(password, BCrypt.gensalt());

  bool verify(String password, String hash) {
    try {
      return BCrypt.checkpw(password, hash);
    } catch (_) {
      return false;
    }
  }
}
