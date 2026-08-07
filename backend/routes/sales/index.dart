import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/list_sales.dart';
import 'package:inventy_backend/src/application/register_sale.dart';
import 'package:inventy_backend/src/domain/entities/sale_item.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';

/// /sales — GET lists history + summary; POST registers a sale.
Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _list(context),
    HttpMethod.post => _register(context),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _list(RequestContext context) async {
  final useCase = await context.read<Future<ListSales>>();
  final records = await useCase.records();
  final summary = await useCase.summary();
  return Response.json(
    body: {
      'sales': records
          .map(
            (s) => {
              'productName': s.productName,
              'detail': s.detail,
              'sku': s.sku,
              'quantity': s.quantity,
              'unitPrice': s.unitPrice,
              'total': s.total,
              'createdAt': s.createdAt.toIso8601String(),
            },
          )
          .toList(),
      'summary': {
        'count': summary.count,
        'totalAll': summary.totalAll,
        'totalToday': summary.totalToday,
        'totalMonth': summary.totalMonth,
        'totalYear': summary.totalYear,
      },
    },
  );
}

/// Body: {"items": [{"productId": "<uuid>", "quantity": 1, "unitPrice": 1999.99}, ...]}
Future<Response> _register(RequestContext context) async {
  final body = await context.request.json() as Map<String, dynamic>;
  final itemsJson = body['items'] as List?;

  if (itemsJson == null || itemsJson.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'La venta no tiene productos'},
    );
  }

  final items = itemsJson.cast<Map<String, dynamic>>().map((m) {
    return SaleItem(
      productId: m['productId'] as String? ?? '',
      quantity: m['quantity'] as int? ?? 0,
      unitPrice: (m['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }).toList();

  final useCase = await context.read<Future<RegisterSale>>();
  try {
    await useCase.call(items);
    return Response(statusCode: HttpStatus.created);
  } on DomainException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.message},
    );
  }
}
