import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/snooze_low_stock.dart';

/// POST /alerts/snooze {productId} — mark a low-stock alert as read.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final body = await context.request.json() as Map<String, dynamic>;
  final id = body['productId'] as String? ?? '';
  if (id.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Falta el producto'},
    );
  }
  final useCase = await context.read<Future<SnoozeLowStock>>();
  await useCase.call(id);
  return Response.json(body: {'ok': true});
}
