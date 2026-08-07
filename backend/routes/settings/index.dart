import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/get_settings.dart';
import 'package:inventy_backend/src/application/update_settings.dart';
import 'package:inventy_backend/src/domain/entities/app_settings.dart';
import 'package:inventy_backend/src/domain/exceptions.dart';

/// /settings — GET reads the shared settings, PUT updates them.
Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _get(context),
    HttpMethod.put => _update(context),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(RequestContext context) async {
  final useCase = await context.read<Future<GetSettings>>();
  return Response.json(body: _json(await useCase.call()));
}

Future<Response> _update(RequestContext context) async {
  final body = await context.request.json() as Map<String, dynamic>;
  final useCase = await context.read<Future<UpdateSettings>>();
  try {
    final settings = await useCase.call(
      businessName: body['businessName'] as String? ?? '',
      defaultThreshold: body['defaultThreshold'] as int? ?? 0,
    );
    return Response.json(body: _json(settings));
  } on DomainException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.message},
    );
  }
}

Map<String, dynamic> _json(AppSettings s) => {
      'businessName': s.businessName,
      'defaultThreshold': s.defaultThreshold,
      'hasLogo': s.hasLogo,
      'logoVersion': s.logoVersion,
    };
