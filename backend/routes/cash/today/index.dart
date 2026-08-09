import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/get_today_sales.dart';

/// GET /cash/today — today's sales total + count (for the cash close).
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final useCase = await context.read<Future<GetTodaySales>>();
  final today = await useCase.call();
  return Response.json(
    body: {'salesTotal': today.total, 'count': today.count},
  );
}
