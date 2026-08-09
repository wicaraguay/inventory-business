import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/authorize_owner.dart';

/// POST /auth/authorize-discount {password} -> {authorized, by}.
/// Any logged-in user (an employee) can ask; it succeeds only if the password
/// matches an owner. Used to unlock a below-list price at the register.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final body = await context.request.json() as Map<String, dynamic>;
  final useCase = await context.read<Future<AuthorizeOwner>>();
  final result = await useCase.call(body['password'] as String? ?? '');
  if (!result.ok) {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'authorized': false, 'error': 'PIN o clave incorrecta'},
    );
  }
  return Response.json(body: {'authorized': true, 'by': result.by});
}
