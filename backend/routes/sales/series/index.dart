import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/list_sales.dart';

/// GET /sales/series?by=day|hour — sales totals over time (for the chart).
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final by =
      context.request.uri.queryParameters['by'] == 'hour' ? 'hour' : 'day';
  final buckets = by == 'hour' ? 24 : 14;

  final useCase = await context.read<Future<ListSales>>();
  final series = await useCase.series(by: by, buckets: buckets);

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
