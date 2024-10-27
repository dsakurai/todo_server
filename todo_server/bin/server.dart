import 'package:todo_core/todo_core.dart';

import 'package:uuid/uuid.dart';

import 'dart:io';

import 'package:sembast/sembast_io.dart';

import 'package:path/path.dart';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'dart:convert' as convert;

class Todo_list {

  final Database database;
  final StoreRef<String, Map<String, Object?>> _store = stringMapStoreFactory.store('todo_list');

  Future<String> add(Todo_node item) async {
    return _store.add(database, item.to_map());
  }

  Future<String> jsonEncode() async {
    final records = await _store.find(database);

    final jsonData = {
      for (var record in records) record.key.toString(): record.value
    };

    return convert.jsonEncode(jsonData);
  }

  Todo_list ({
    required this.database
  });

}

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

Future<void> insertRecord(Database db, StoreRef<String, Map<String, Object?>> store) async {
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

    final todo_data = Todo_list(database: db);

    final child = Todo_node( text:"Buy milk.",    node_id: Uuid().v4());

    await todo_data.add(child);
    await todo_data.add(Todo_node( text: "Watch movie", node_id: Uuid().v4(), children: [child])); // A project without a task; used to save a project even if it's empty.
    await todo_data.add(Todo_node( text: "Homework",    node_id: Uuid().v4())); // A project without a task; used to save a project even if it's empty.

    // Get all data
    final str = await todo_data.jsonEncode();
    print(str);

    // Configure a pipeline that logs requests.
    await startServer();

  } finally {
    await db.close();
  }


}
