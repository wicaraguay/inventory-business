import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/cash_close.dart';
import 'package:inventy_backend/src/domain/entities/user.dart';

/// /cash — GET lists recent closes; POST saves a new close (arqueo). Owner-only.
Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _list(context),
    HttpMethod.post => _save(context),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _list(RequestContext context) async {
  final useCase = await context.read<Future<ListCashCloses>>();
  final closes = await useCase.call();
  return Response.json(
    body: {'closes': closes.map((c) => c.toJson()).toList()},
  );
}

Future<Response> _save(RequestContext context) async {
  final body = await context.request.json() as Map<String, dynamic>;
  final useCase = await context.read<Future<SaveCashClose>>();
  final by = context.read<User?>()?.displayName;
  final close = await useCase.call(
    openingFloat: (body['openingFloat'] as num?)?.toDouble() ?? 0,
    salesTotal: (body['salesTotal'] as num?)?.toDouble() ?? 0,
    counted: (body['counted'] as num?)?.toDouble() ?? 0,
    closedBy: by,
  );
  return Response.json(statusCode: HttpStatus.created, body: close.toJson());
}
