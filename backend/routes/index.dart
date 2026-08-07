import 'package:dart_frog/dart_frog.dart';

/// Health check.
Response onRequest(RequestContext context) {
  return Response.json(body: {'service': 'inventy-backend', 'status': 'ok'});
}
