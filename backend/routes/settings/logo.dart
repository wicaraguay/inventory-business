import 'dart:io';
import 'dart:typed_data';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/business_logo.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';

/// /settings/logo — GET serves the logo (public), PUT/POST stores it,
/// DELETE removes it (owner-only, enforced in middleware).
Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _get(context),
    HttpMethod.put || HttpMethod.post => _save(context),
    HttpMethod.delete => _delete(context),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(RequestContext context) async {
  final useCase = await context.read<Future<GetBusinessLogo>>();
  final logo = await useCase.call();
  if (logo == null) return Response(statusCode: HttpStatus.notFound);
  return Response.bytes(
    body: logo.data,
    headers: {
      HttpHeaders.contentTypeHeader: logo.contentType,
      HttpHeaders.cacheControlHeader: 'public, max-age=31536000, immutable',
    },
  );
}

Future<Response> _save(RequestContext context) async {
  final useCase = await context.read<Future<SaveBusinessLogo>>();
  final chunks = await context.request.bytes().toList();
  final bytes = Uint8List.fromList(chunks.expand((c) => c).toList());
  final contentType =
      context.request.headers[HttpHeaders.contentTypeHeader] ?? 'image/jpeg';
  try {
    await useCase.call(bytes, contentType);
    return Response(statusCode: HttpStatus.noContent);
  } on DomainException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.message},
    );
  }
}

Future<Response> _delete(RequestContext context) async {
  final useCase = await context.read<Future<DeleteBusinessLogo>>();
  await useCase.call();
  return Response(statusCode: HttpStatus.noContent);
}
