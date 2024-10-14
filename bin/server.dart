import 'dart:convert' as convert;
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

class Todo_item {
  Todo_value value;
  String hash;

  Todo_item(
    {
      required this.value,
      required this.hash
    }
  );
}

enum GTD_tag {
  Now,
  Waiting,
  Someday,
  Context,
  Reference
}

class Task {
  String text;
  GTD_tag gtd_tag;

  Map<String, Object?> to_map() {
    return {
      "text" : text,
      "gtd_tag": gtd_tag.name
    };
  }

  Task (
    {this.text    = "",
     this.gtd_tag = GTD_tag.Now
    }
  );
}

class Todo_value {

  String group; // Used for creating, e.g., a "Private" group
  String project;
  Task? task;

  Map<String, Object?> to_map() {
    return {
      "group":   group,
      "project": project,
      "task":    task?.to_map(),
    };
  }

  Todo_value(
    {
      this.group   = "",
      this.project = "",
      this.task,
    }
  );
}

class Todo_list {

  final Database database;
  final StoreRef<String, Map<String, Object?>> _store = stringMapStoreFactory.store('todo_list');

  Future<String> add(Todo_value item) async {
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

void main(List<String> args) async {

  final db = await initDatabase();

  try {

    final todo_list = Todo_list(database: db);
    await todo_list.add(Todo_value(
                          task: Task(text:"Buy milk."),
                          project: "Grocery store"));
    await todo_list.add(Todo_value(
                          group:   "Friends only")); // A project without a task; used to save a project even if it's empty.
    await todo_list.add(Todo_value(
                          group:   "Private",
                          project: "Watch movie")); // A project without a task; used to save a project even if it's empty.
    await todo_list.add(Todo_value(
                          project: "Homework")); // A project without a task; used to save a project even if it's empty.

    // Get all data
    final str = await todo_list.jsonEncode();
    print(str);

    // Configure a pipeline that logs requests.
    await startServer();

  } finally {
    await db.close();
  }


}
