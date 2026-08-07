import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/create_user.dart';
import 'package:inventy_backend/src/application/list_users.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';

/// /users — GET lists users, POST creates one. Owner-only (enforced in middleware).
Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _list(context),
    HttpMethod.post => _create(context),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _list(RequestContext context) async {
  final useCase = await context.read<Future<ListUsers>>();
  final users = await useCase.call();
  return Response.json(
    body: {'users': users.map((u) => u.toJson()).toList()},
  );
}

Future<Response> _create(RequestContext context) async {
  final body = await context.request.json() as Map<String, dynamic>;
  final useCase = await context.read<Future<CreateUser>>();
  try {
    final user = await useCase.call(
      username: body['username'] as String? ?? '',
      password: body['password'] as String? ?? '',
      role: body['role'] as String? ?? 'employee',
      displayName: body['displayName'] as String? ?? '',
    );
    return Response.json(statusCode: HttpStatus.created, body: user.toJson());
  } on DomainException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.message},
    );
  }
}
