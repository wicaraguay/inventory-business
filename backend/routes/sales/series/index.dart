import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/list_sales.dart';
import 'package:inventy_backend/src/domain/entities/sales_bucket.dart';

/// GET /sales/series
///  - ?from=YYYY-MM-DD&to=YYYY-MM-DD → daily totals across an explicit range.
///  - ?by=day|hour                   → last 14 days / last 24 hours (default).
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final q = context.request.uri.queryParameters;
  final useCase = await context.read<Future<ListSales>>();

  // Explicit date range takes precedence.
  final fromRaw = q['from'];
  final toRaw = q['to'];
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
    // Cap the span so a huge range can't hammer the DB.
    if (to.difference(from).inDays > 366) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'El rango máximo es de 366 días'},
      );
    }
    final series = await useCase.seriesRange(from: from, to: to);
    return _seriesResponse('day', series);
  }

  final by = q['by'] == 'hour' ? 'hour' : 'day';
  final buckets = by == 'hour' ? 24 : 14;
  final series = await useCase.series(by: by, buckets: buckets);
  return _seriesResponse(by, series);
}

Response _seriesResponse(String by, List<SalesBucket> series) {
  return Response.json(
    body: {
      'by': by,
      'series': series
          .map(
            (b) => {
              'bucket': b.bucket.toIso8601String(),
              'total': b.total,
            },
          )
          .toList(),
    },
  );
}
