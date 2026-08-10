// ignore_for_file: file_names
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/mark_products_labeled.dart';

/// POST /products/mark-labeled — mark products as labeled (or back to pending).
/// Body: {"ids": ["<uuid>", ...], "labeled": true}.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final body = await context.request.json() as Map<String, dynamic>;
  final ids = (body['ids'] as List?)?.map((e) => e.toString()).toList() ?? [];
  final labeled = body['labeled'] as bool? ?? true;
  if (ids.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'No hay productos para marcar'},
    );
  }
  final useCase = await context.read<Future<MarkProductsLabeled>>();
  await useCase.call(ids, labeled: labeled);
  return Response(statusCode: HttpStatus.noContent);
}
