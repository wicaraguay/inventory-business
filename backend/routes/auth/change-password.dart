import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/change_password.dart';
import 'package:inventy_backend/src/domain/entities/user.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';

/// POST /auth/change-password {currentPassword, newPassword}.
/// Any logged-in user changes their own password.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final user = context.read<User?>();
  if (user == null) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'error': 'No autenticado'},
    );
  }
  final body = await context.request.json() as Map<String, dynamic>;
  final useCase = await context.read<Future<ChangePassword>>();
  try {
    await useCase.call(
      current: user,
      currentPassword: body['currentPassword'] as String? ?? '',
      newPassword: body['newPassword'] as String? ?? '',
    );
    return Response.json(body: {'ok': true});
  } on DomainException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.message},
    );
  }
}
