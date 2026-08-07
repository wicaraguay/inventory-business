import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/detect_low_stock.dart';

/// GET /alerts — products at or below their threshold (low-stock alerts).
/// Lives outside /products to avoid the /products/[id] dynamic route.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final useCase = await context.read<Future<DetectLowStock>>();
  final products = await useCase.call();

  return Response.json(
    body: {
      'lowStock': products
          .map(
            (p) => {
              'productId': p.productId,
              'name': p.name,
              'detail': p.detail,
              'sku': p.sku,
              'currentStock': p.currentStock,
              'threshold': p.threshold,
            },
          )
          .toList(),
    },
  );
}
