// ignore_for_file: file_names
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/add_model_sizes.dart';
import 'package:inventy_backend/src/domain/entities/bulk_product_input.dart';
import 'package:inventy_backend/src/domain/entities/product.dart';
import 'package:inventy_backend/src/domain/entities/user.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';

/// POST /products/model/<modelId>/sizes — add more sizes to an existing model
/// (same model_id, prices, and image). Body: {"items": [BulkProductInput...]}.
Future<Response> onRequest(RequestContext context, String modelId) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final body = await context.request.json() as Map<String, dynamic>;
  final itemsJson = body['items'] as List?;
  if (itemsJson == null || itemsJson.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'No hay tallas para agregar'},
    );
  }

  final items = itemsJson.cast<Map<String, dynamic>>().map((m) {
    return BulkProductInput(
      name: m['name'] as String? ?? '',
      sku: m['sku'] as String? ?? '',
      detail: m['detail'] as String?,
      lowStockThreshold: m['lowStockThreshold'] as int? ?? 0,
      salePrice: (m['salePrice'] as num?)?.toDouble(),
      minPrice: (m['minPrice'] as num?)?.toDouble(),
      supplierPrice: (m['supplierPrice'] as num?)?.toDouble(),
      initialStock: m['initialStock'] as int? ?? 0,
    );
  }).toList();

  final useCase = await context.read<Future<AddModelSizes>>();
  final owner = context.read<User?>()?.isOwner ?? false;
  try {
    final created = await useCase.call(modelId, items);
    return Response.json(
      statusCode: HttpStatus.created,
      body: {'products': [for (final p in created) _json(p, withSupplier: owner)]},
    );
  } on DomainException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.message},
    );
  }
}

/// New sizes start at 0 stock and inherit the model's image (copied server-side).
Map<String, dynamic> _json(Product p, {required bool withSupplier}) => {
      'id': p.id,
      'name': p.name,
      'detail': p.detail,
      'sku': p.sku,
      'lowStockThreshold': p.lowStockThreshold,
      'salePrice': p.salePrice,
      'minPrice': p.minPrice,
      'modelId': p.modelId,
      'currentStock': 0,
      'hasImage': true,
      'imageVersion': 0,
      if (withSupplier) 'supplierPrice': p.supplierPrice,
    };
