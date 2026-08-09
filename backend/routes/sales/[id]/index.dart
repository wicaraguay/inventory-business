// ignore_for_file: file_names
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/void_sale.dart';
import 'package:inventy_backend/src/domain/entities/user.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';

/// DELETE /sales/<id> — voids (anula) the sale. Owner-only (in middleware).
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.delete) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final useCase = await context.read<Future<VoidSale>>();
  final by = context.read<User?>()?.displayName;
  try {
    await useCase.call(id, by);
    return Response(statusCode: HttpStatus.noContent);
  } on DomainException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.message},
    );
  }
}
