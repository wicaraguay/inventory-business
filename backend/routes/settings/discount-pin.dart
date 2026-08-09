import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/set_discount_pin.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';

/// PUT /settings/discount-pin {pin} — owner sets/changes the discount PIN.
/// Owner-only (non-GET /settings/* is gated in the middleware).
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.put) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final body = await context.request.json() as Map<String, dynamic>;
  final useCase = await context.read<Future<SetDiscountPin>>();
  try {
    await useCase.call(body['pin'] as String? ?? '');
    return Response.json(body: {'ok': true});
  } on DomainException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.message},
    );
  }
}
