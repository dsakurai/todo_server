import 'dart:io';

import 'package:sembast/sembast_io.dart';

import 'package:path/path.dart';

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

Future<Database> initDatabase() async {
  final directory = Directory.current;
  final dbPath = join(directory.path, 'todo_list.json');
  final database = await databaseFactoryIo.openDatabase(dbPath);
  return database;
}

Future<void> insertRecord(Database db, StoreRef<int, Map<String, Object?>> store) async {
  final key = await store.add(db, {'task_item': 'Buy milk', 'tag': 'NOW', 'project': 'Inbox'});
  print('Inserted record with key: $key');
}

Future<(InternetAddress,HttpServer)> startServer() async {

  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;
  HttpServer? server;

  // For running in containers, we respect the PORT environment variable.
  var port = int.parse(Platform.environment['PORT'] ?? '8080');

  // Configure a pipeline that logs requests.
  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(_router.call);

  try {
    server = await serve(handler, ip, port);
  } on SocketException catch (e) {

    print("Unable to bind to the port.");
    rethrow;
  }
  
  if (server != null) {
    print('Server listening on port ${server.port}');
    return (ip, server);
  }

  throw Exception("Failed to start server.");
}

void main(List<String> args) async {

  final db = await initDatabase();

  try {

    final StoreRef<int, Map<String, Object?>> store = intMapStoreFactory.store('todo_list');
    insertRecord(db, store);

    // Configure a pipeline that logs requests.
    await startServer();

  } finally {
    await db.close();
  }


}
