import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/list_movements.dart';
import 'package:inventy_backend/src/application/register_stock_entry.dart';
import 'package:inventy_backend/src/application/register_stock_exit.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';

/// /movements — GET lists the history; POST registers a movement.
Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _list(context),
    HttpMethod.post => _register(context),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _list(RequestContext context) async {
  final useCase = await context.read<Future<ListMovements>>();
  final movements = await useCase.call();
  return Response.json(
    body: {
      'movements': movements
          .map(
            (m) => {
              'productName': m.productName,
              'detail': m.detail,
              'sku': m.sku,
              'type': m.type.name,
              'quantity': m.quantity,
              'note': m.note,
              'createdAt': m.createdAt.toIso8601String(),
            },
          )
          .toList(),
    },
  );
}

/// Body: {"productId": "<uuid>", "quantity": 5, "type": "entry"|"exit", "note": "opcional"}
Future<Response> _register(RequestContext context) async {
  final body = await context.request.json() as Map<String, dynamic>;
  final productId = body['productId'] as String?;
  final quantity = body['quantity'] as int?;
  final type = body['type'] as String?;
  final note = body['note'] as String?;

  if (productId == null || quantity == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'productId y quantity son obligatorios'},
    );
  }

  try {
    switch (type) {
      case 'entry':
        final useCase = await context.read<Future<RegisterStockEntry>>();
        await useCase.call(productId, quantity, note: note);
      case 'exit':
        final useCase = await context.read<Future<RegisterStockExit>>();
        await useCase.call(productId, quantity, note: note);
      default:
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'error': "type debe ser 'entry' o 'exit'"},
        );
    }
    return Response(statusCode: HttpStatus.created);
  } on DomainException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.message},
    );
  }
}
