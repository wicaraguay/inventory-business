import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/list_sales.dart';
import 'package:inventy_backend/src/application/register_sale.dart';
import 'package:inventy_backend/src/domain/entities/sale_item.dart';
import 'package:inventy_backend/src/domain/entities/sale_record.dart';
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

  // Optional date filter: ?from=YYYY-MM-DD&to=YYYY-MM-DD → records in that
  // local-date range (so the owner can see any past period). Without it, the
  // list stays as the most-recent sales.
  final q = context.request.uri.queryParameters;
  final fromRaw = q['from'];
  final toRaw = q['to'];

  final List<SaleRecord> records;
  if (fromRaw != null && toRaw != null) {
    final from = DateTime.tryParse(fromRaw);
    final to = DateTime.tryParse(toRaw);
    if (from == null || to == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Fechas inválidas (usá YYYY-MM-DD)'},
      );
    }
    if (to.isBefore(from)) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'La fecha "hasta" no puede ser anterior a "desde"'},
      );
    }
    if (to.difference(from).inDays > 366) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'El rango máximo es de 366 días'},
      );
    }
    records = await useCase.recordsInRange(from: from, to: to);
  } else {
    records = await useCase.records();
  }

  final summary = await useCase.summary();
  return Response.json(
    body: {
      'sales': records
          .map(
            (s) => {
              'id': s.id,
              'productName': s.productName,
              'detail': s.detail,
              'sku': s.sku,
              'quantity': s.quantity,
              'unitPrice': s.unitPrice,
              'total': s.total,
              'createdAt': s.createdAt.toIso8601String(),
              'voidedAt': s.voidedAt?.toIso8601String(),
              'voidedBy': s.voidedBy,
              'description': s.description,
              'sizeLabel': s.sizeLabel,
            },
          )
          .toList(),
      'summary': {
        'count': summary.count,
        'totalAll': summary.totalAll,
        'totalToday': summary.totalToday,
        'totalWeek': summary.totalWeek,
        'totalMonth': summary.totalMonth,
        'totalQuarter': summary.totalQuarter,
        'totalYear': summary.totalYear,
        'profitToday': summary.profitToday,
        'profitWeek': summary.profitWeek,
        'profitMonth': summary.profitMonth,
        'profitQuarter': summary.profitQuarter,
        'profitYear': summary.profitYear,
      },
    },
  );
}

/// Body: {"items": [{"productId": "<uuid>|null", "quantity": 1, "unitPrice": 1999.99,
///                   "description": "...", "sizeLabel": "38", "createdAt": "ISO8601"}, ...]}
/// Quick sale: omit productId or send null/empty; description is then required.
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
    final createdAtRaw = m['createdAt'] as String?;
    return SaleItem(
      productId: m['productId'] as String?,
      quantity: m['quantity'] as int? ?? 0,
      unitPrice: (m['unitPrice'] as num?)?.toDouble() ?? 0,
      total: (m['total'] as num?)?.toDouble(),
      description: m['description'] as String?,
      sizeLabel: m['sizeLabel'] as String?,
      createdAt: createdAtRaw != null ? DateTime.parse(createdAtRaw) : null,
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
