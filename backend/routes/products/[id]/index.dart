import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/delete_product.dart';
import 'package:inventy_backend/src/application/update_product.dart';
import 'package:inventy_backend/src/domain/entities/user.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';

/// /products/<id> — PUT updates, DELETE removes.
Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.put => _update(context, id),
    HttpMethod.delete => _delete(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _update(RequestContext context, String id) async {
  final body = await context.request.json() as Map<String, dynamic>;
  final useCase = await context.read<Future<UpdateProduct>>();
  final isOwner = context.read<User?>()?.isOwner ?? false;
  try {
    final product = await useCase.call(
      id: id,
      name: body['name'] as String? ?? '',
      sku: body['sku'] as String? ?? '',
      lowStockThreshold: body['lowStockThreshold'] as int? ?? 0,
      detail: body['detail'] as String?,
      salePrice: (body['salePrice'] as num?)?.toDouble(),
      minPrice: (body['minPrice'] as num?)?.toDouble(),
      supplierPrice: (body['supplierPrice'] as num?)?.toDouble(),
    );
    return Response.json(
      body: {
        'id': product.id,
        'name': product.name,
        'detail': product.detail,
        'sku': product.sku,
        'lowStockThreshold': product.lowStockThreshold,
        'salePrice': product.salePrice,
        'minPrice': product.minPrice,
        'modelId': product.modelId,
        if (isOwner) 'supplierPrice': product.supplierPrice,
      },
    );
  } on DomainException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.message},
    );
  }
}

Future<Response> _delete(RequestContext context, String id) async {
  final useCase = await context.read<Future<DeleteProduct>>();
  try {
    await useCase.call(id);
    return Response(statusCode: HttpStatus.noContent);
  } on DomainException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.message},
    );
  }
}
