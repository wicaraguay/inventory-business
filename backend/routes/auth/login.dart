import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/login.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';

/// POST /auth/login {username, password} -> {token, user}. Public.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final body = await context.request.json() as Map<String, dynamic>;
  final useCase = await context.read<Future<Login>>();
  try {
    final result = await useCase.call(
      body['username'] as String? ?? '',
      body['password'] as String? ?? '',
    );
    return Response.json(
      body: {'token': result.token, 'user': result.user.toJson()},
    );
  } on DomainException catch (e) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'error': e.message},
    );
  }
}
