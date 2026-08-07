import 'dart:io';
import 'dart:typed_data';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/delete_product_image.dart';
import 'package:inventy_backend/src/application/get_product_image.dart';
import 'package:inventy_backend/src/application/save_product_image.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';

/// /products/<id>/image — GET serves the image, PUT/POST stores it, DELETE removes.
Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id),
    HttpMethod.put || HttpMethod.post => _save(context, id),
    HttpMethod.delete => _delete(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(RequestContext context, String id) async {
  final useCase = await context.read<Future<GetProductImage>>();
  final image = await useCase.call(id);
  if (image == null) {
    return Response(statusCode: HttpStatus.notFound);
  }
  return Response.bytes(
    body: image.data,
    headers: {
      HttpHeaders.contentTypeHeader: image.contentType,
      // Safe to cache hard: the URL is versioned (?v=<imageVersion>).
      HttpHeaders.cacheControlHeader: 'public, max-age=31536000, immutable',
    },
  );
}

Future<Response> _save(RequestContext context, String id) async {
  final useCase = await context.read<Future<SaveProductImage>>();
  // request.bytes() is a Stream<List<int>> here — collect it into one buffer.
  final chunks = await context.request.bytes().toList();
  final bytes = Uint8List.fromList(chunks.expand((c) => c).toList());
  final contentType =
      context.request.headers[HttpHeaders.contentTypeHeader] ?? 'image/jpeg';
  try {
    await useCase.call(id, bytes, contentType);
    return Response(statusCode: HttpStatus.noContent);
  } on DomainException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.message},
    );
  }
}

Future<Response> _delete(RequestContext context, String id) async {
  final useCase = await context.read<Future<DeleteProductImage>>();
  await useCase.call(id);
  return Response(statusCode: HttpStatus.noContent);
}
