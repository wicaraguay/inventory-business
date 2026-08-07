import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/domain/entities/user.dart';

/// GET /auth/me -> the current user (used to validate a saved session).
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final user = context.read<User?>();
  if (user == null) return Response(statusCode: HttpStatus.unauthorized);
  return Response.json(body: user.toJson());
}
