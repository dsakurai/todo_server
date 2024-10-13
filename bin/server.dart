import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler);

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(_router.call);

  // For running in containers, we respect the PORT environment variable.
  var port = int.parse(Platform.environment['PORT'] ?? '8080');
  int attempt = 0;

  final attempt_max = 10;

  HttpServer? server = null;

  while ( attempt < attempt_max ) {
    try {
      server = await serve(handler, ip, port);
      break;
    } on SocketException catch (e) {
      port++;
      attempt++;

      if (attempt == attempt_max) {
        print("Unable to bind to a port after $attempt_max attempts.");
        exit(1);
      }
    }
  }

  if (server != null) {
  print('Server listening on port ${server.port}');
  }
}
