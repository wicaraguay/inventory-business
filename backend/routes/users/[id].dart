// ignore_for_file: file_names
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/delete_user.dart';
import 'package:inventy_backend/src/application/update_user.dart';
import 'package:inventy_backend/src/domain/entities/user.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';

/// /users/<id> — PUT edits the user, DELETE removes them. Owner-only.
Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.put => _update(context, id),
    HttpMethod.delete => _delete(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _update(RequestContext context, String id) async {
  final body = await context.request.json() as Map<String, dynamic>;
  final useCase = await context.read<Future<UpdateUser>>();
  try {
    final user = await useCase.call(
      id: id,
      username: body['username'] as String? ?? '',
      role: body['role'] as String? ?? '',
      displayName: body['displayName'] as String? ?? '',
      canManageInventory: body['canManageInventory'] as bool? ?? false,
      newPassword: body['newPassword'] as String?,
    );
    return Response.json(body: user.toJson());
  } on DomainException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.message},
    );
  }
}

Future<Response> _delete(RequestContext context, String id) async {
  final useCase = await context.read<Future<DeleteUser>>();
  final me = context.read<User?>();
  try {
    await useCase.call(id, requestedByUserId: me?.id ?? '');
    return Response(statusCode: HttpStatus.noContent);
  } on DomainException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.message},
    );
  }
}
