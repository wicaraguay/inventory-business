import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/create_product.dart';
import 'package:inventy_backend/src/application/create_products_bulk.dart';
import 'package:inventy_backend/src/application/find_product_by_code.dart';
import 'package:inventy_backend/src/application/get_model_sizes.dart';
import 'package:inventy_backend/src/application/list_products.dart';
import 'package:inventy_backend/src/domain/entities/bulk_product_input.dart';
import 'package:inventy_backend/src/domain/entities/product.dart';
import 'package:inventy_backend/src/domain/entities/product_with_stock.dart';
import 'package:inventy_backend/src/domain/entities/user.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';

/// /products — POST creates; GET lists; GET ?code=<sku|barcode> resolves a scan.
Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.post => _create(context),
    HttpMethod.get => _get(context),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

/// Whether the current request may see the supplier (cost) price. Owner only.
bool _isOwner(RequestContext context) =>
    context.read<User?>()?.isOwner ?? false;

Future<Response> _get(RequestContext context) async {
  final code = context.request.uri.queryParameters['code'];
  if (code != null) return _findByCode(context, code);
  return _list(context);
}

Future<Response> _list(RequestContext context) async {
  final useCase = await context.read<Future<ListProducts>>();
  final products = await useCase.call();
  final owner = _isOwner(context);
  return Response.json(
    body: {
      'products': [
        for (final p in products) _withStockJson(p, withSupplier: owner),
      ],
    },
  );
}

Future<Response> _findByCode(RequestContext context, String code) async {
  final useCase = await context.read<Future<FindProductByCode>>();
  try {
    final found = await useCase.call(code);
    if (found == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'No existe un producto con ese código'},
      );
    }
    // The register never shows the cost price (withSupplier: false), but it does
    // show the model's other available sizes.
    final json = _withStockJson(found, withSupplier: false);
    final modelId = found.product.modelId;
    if (modelId != null) {
      final sizes = await (await context.read<Future<GetModelSizes>>())
          .call(modelId);
      json['sizes'] = [
        for (final s in sizes)
          {
            'productId': s.productId,
            'label': s.label,
            'currentStock': s.currentStock,
          },
      ];
    }
    return Response.json(body: json);
  } on DomainException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.message},
    );
  }
}

Future<Response> _create(RequestContext context) async {
  final body = await context.request.json() as Map<String, dynamic>;
  if (body['items'] is List) {
    return _createBulk(context, body['items'] as List);
  }
  final useCase = await context.read<Future<CreateProduct>>();
  try {
    final product = await useCase.call(
      name: body['name'] as String? ?? '',
      sku: body['sku'] as String? ?? '',
      lowStockThreshold: body['lowStockThreshold'] as int? ?? 0,
      detail: body['detail'] as String?,
      salePrice: (body['salePrice'] as num?)?.toDouble(),
      minPrice: (body['minPrice'] as num?)?.toDouble(),
      supplierPrice: (body['supplierPrice'] as num?)?.toDouble(),
    );
    return Response.json(
      statusCode: HttpStatus.created,
      body: _productJson(product, 0, withSupplier: _isOwner(context)),
    );
  } on DomainException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.message},
    );
  }
}

Future<Response> _createBulk(
  RequestContext context,
  List<dynamic> itemsJson,
) async {
  final useCase = await context.read<Future<CreateProductsBulk>>();
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

  try {
    final created = await useCase.call(items);
    final owner = _isOwner(context);
    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'products': [
          for (final p in created) _productJson(p, 0, withSupplier: owner),
        ],
      },
    );
  } on DomainException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.message},
    );
  }
}

Map<String, dynamic> _withStockJson(
  ProductWithStock p, {
  required bool withSupplier,
}) =>
    _productJson(
      p.product,
      p.currentStock,
      hasImage: p.hasImage,
      imageVersion: p.imageVersion,
      withSupplier: withSupplier,
    );

Map<String, dynamic> _productJson(
  Product p,
  int currentStock, {
  bool hasImage = false,
  int imageVersion = 0,
  bool withSupplier = false,
}) =>
    {
      'id': p.id,
      'name': p.name,
      'detail': p.detail,
      'sku': p.sku,
      'lowStockThreshold': p.lowStockThreshold,
      'salePrice': p.salePrice,
      'minPrice': p.minPrice,
      'modelId': p.modelId,
      'currentStock': currentStock,
      'hasImage': hasImage,
      'imageVersion': imageVersion,
      // Cost price only for the owner; never leaves the server for employees.
      if (withSupplier) 'supplierPrice': p.supplierPrice,
    };
