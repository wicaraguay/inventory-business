import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/bootstrap_owner.dart';
import 'package:inventy_backend/src/application/create_user.dart';
import 'package:inventy_backend/src/infrastructure/auth/password_hasher.dart';
import 'package:inventy_backend/src/infrastructure/postgres/database.dart';
import 'package:inventy_backend/src/infrastructure/postgres/postgres_user_repository.dart';

/// dart_frog custom entrypoint: seed the initial owner (from env) on first boot,
/// then start serving.
Future<HttpServer> run(Handler handler, InternetAddress ip, int port) async {
  try {
    final users = PostgresUserRepository(await Database.connection());
    await BootstrapOwner(users, CreateUser(users, PasswordHasher())).call();
  } on Object catch (e) {
    // Never block startup if seeding fails (e.g. DB not ready yet).
    stderr.writeln('bootstrap owner skipped: $e');
  }
  return serve(handler, ip, port);
}
